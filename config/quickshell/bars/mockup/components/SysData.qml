import Quickshell
import Quickshell.Io
import QtQuick

// Single data source for the whole mockup bar. Every popup reads from here.
// Real data where a cheap source exists (/proc, df, wpctl, nmcli, bluetoothctl).
Scope {
    id: sys

    // Palette (pywal fallbacks, same as the mockup)
    property color bg: "#122957"
    property color fg: "#c6cff5"
    property color accent: "#8e81d9"
    property color secondary: "#3f5ac8"
    property color dark: "#0a1633"

    // ---- CPU ----
    property string cpuModel: "CPU"
    property int cpuPercent: 0
    property var cpuCores: []
    property int cpuTemp: -1
    property string cpuLoad: "-"
    property string cpuFreq: "-"
    property string cpuUptime: "-"
    property var prevCpu: null

    // ---- RAM (GB) ----
    property real ramTotalGb: 0
    property real ramUsedGb: 0
    property real ramAvailGb: 0
    property real ramBuffersGb: 0
    property real ramCachedGb: 0
    property real swapTotalGb: 0
    property real swapUsedGb: 0

    // ---- Disks ----
    property var disks: []

    // ---- Audio ----
    property var audioOutputs: []   // [{id, name, active}]
    property var audioInputs: []
    property real outVolume: 0.5
    property real inVolume: 0.5
    property bool outMuted: false
    property bool inMuted: false

    // ---- Network / Bluetooth ----
    property bool wifiOn: true
    property string wifiSsid: "Not connected"
    property int wifiSignal: 0
    property string wifiSpeed: "—"
    property string wifiBand: ""
    property string wifiIp: "—"

    Process {
        id: wifiIpProc
        command: ["sh", "-c", "nmcli -g IP4.ADDRESS device show 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: sys.wifiIp = this.text.trim().split("/")[0] || "—" }
    }
    function refreshWifiIp() { wifiIpProc.running = true; }
    property var wifiNetworks: []   // [{ssid, signal, security, active, speed, frequency}]
    property bool wifiScanning: false
    property bool btOn: true
    property var btDevices: []      // [{mac, name, connected}]

    // ---- Window title / workspaces (niri) ----
    property string windowTitle: ""

    function pad(n) { return (n < 10 ? "0" : "") + n; }

    function gb(kb) { return kb / 1048576; }

    function parseCpu(text) {
        const lines = text.split("\n").filter(l => l.startsWith("cpu"));
        const cores = [];
        const now = {};
        for (const line of lines) {
            const f = line.trim().split(/\s+/);
            const name = f[0];
            const n = f.slice(1).map(Number);
            const total = n.reduce((a, b) => a + b, 0);
            const idle = n[3] + (n[4] || 0);
            now[name] = { total: total, idle: idle };
            if (name === "cpu") continue;
            const prev = sys.prevCpu ? sys.prevCpu[name] : null;
            let pct = 0;
            if (prev && total > prev.total)
                pct = Math.round(100 * (1 - (idle - prev.idle) / (total - prev.total)));
            cores.push(pct);
        }
        const prevAll = sys.prevCpu ? sys.prevCpu["cpu"] : null;
        const all = now["cpu"];
        if (prevAll && all && all.total > prevAll.total)
            sys.cpuPercent = Math.round(100 * (1 - (all.idle - prevAll.idle) / (all.total - prevAll.total)));
        sys.prevCpu = now;
        if (sys.prevCpu && cores.length) sys.cpuCores = cores;
    }

    function parseMem(text) {
        const get = key => {
            const m = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
            return m ? Number(m[1]) : 0;
        };
        const total = get("MemTotal"), avail = get("MemAvailable");
        sys.ramTotalGb = gb(total);
        sys.ramAvailGb = gb(avail);
        sys.ramUsedGb = gb(total - avail);
        sys.ramBuffersGb = gb(get("Buffers"));
        sys.ramCachedGb = gb(get("Cached"));
        sys.swapTotalGb = gb(get("SwapTotal"));
        sys.swapUsedGb = gb(get("SwapTotal") - get("SwapFree"));
    }

    function humanSize(bytes) {
        const g = bytes / 1073741824;
        return g >= 1000 ? (g / 1024).toFixed(1) + "T" : g.toFixed(g < 10 ? 1 : 0) + "G";
    }

    function parseDf(text) {
        const out = [];
        for (const line of text.split("\n").slice(1)) {
            const f = line.trim().split(/\s+/);
            if (f.length < 5) continue;
            const size = Number(f[2]), used = Number(f[3]);
            out.push({
                device: f[0],
                mount: f[5] || f[1],
                sizeHuman: humanSize(size),
                usedHuman: humanSize(used),
                percent: size > 0 ? Math.round(100 * used / size) : 0
            });
        }
        sys.disks = out;
    }

    function parseWpctl(text, section) {
        const devices = [];
        let inSection = false;
        for (const line of text.split("\n")) {
            if (line.includes(section + ":")) { inSection = true; continue; }
            if (line.includes("endpoints:")) { inSection = false; continue; }
            if (!inSection) continue;
            const m = line.match(/(\*?)\s*(\d+)\.\s+(.+)$/);
            if (!m) continue;
            devices.push({ id: m[2], name: m[3].split(" [")[0].trim(), active: m[1] === "*" });
        }
        return devices;
    }

    function parseVolume(text) {
        const m = text.match(/Volume:\s*([0-9.]+)/);
        return m ? Math.max(0, Math.min(1.5, Number(m[1]))) : null;
    }

    function parseNmcli(text) {
        const nets = [];
        for (const line of text.split("\n")) {
            const f = line.split(":");
            if (f.length < 4 || !f[1]) continue;
            const ssid = f[1].replace(/\\:/g, ":");
            nets.push({ active: f[0] === "yes", ssid: ssid, signal: Number(f[2]) || 0, security: f[3] || "Open", speed: f[4] || "—", frequency: Number(f[5]) || 0 });
        }
        sys.wifiNetworks = nets;
        const active = nets.find(n => n.active);
        sys.wifiSsid = active ? active.ssid : "Not connected";
        sys.wifiSignal = active ? active.signal : 0;
        sys.wifiSpeed = active ? active.speed : "—";
        sys.wifiBand = active ? (active.frequency >= 4900 ? "5 GHz" : (active.frequency >= 2400 ? "2.4 GHz" : "")) : "";
    }

    // ---- One-time reads ----
    FileView { id: cpuInfo; path: "/proc/cpuinfo"; onLoaded: {
        const m = text().match(/model name\s*:\s*(.+)/);
        if (m) sys.cpuModel = m[1].trim();
        const f = text().match(/cpu MHz\s*:\s*([0-9.]+)/);
        if (f) sys.cpuFreq = (Number(f[1]) / 1000).toFixed(1) + " GHz";
    } }

    // ---- Periodic reads ----
    FileView { id: statFile; path: "/proc/stat"; onLoaded: sys.parseCpu(text()) }
    FileView { id: memFile; path: "/proc/meminfo"; onLoaded: sys.parseMem(text()) }
    FileView { id: loadFile; path: "/proc/loadavg"; onLoaded: {
        const f = text().trim().split(/\s+/);
        sys.cpuLoad = f.slice(0, 3).join(" ");
    } }
    FileView { id: uptimeFile; path: "/proc/uptime"; onLoaded: {
        const s = Math.floor(Number(text().split(" ")[0]));
        const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
        sys.cpuUptime = (d > 0 ? d + "d " : "") + h + "h " + m + "m";
    } }

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = Number(this.text.trim());
                sys.cpuTemp = v > 0 ? Math.round(v / 1000) : -1;
            }
        }
    }

    Process {
        id: dfProc
        command: ["sh", "-c", "df -B1 --output=source,target,size,used,pcent -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs 2>/dev/null | awk 'NR==1 || $1 ~ /^\\/dev/'"]
        stdout: StdioCollector { onStreamFinished: sys.parseDf(this.text) }
    }

    Process {
        id: wpctlStatus
        command: ["sh", "-c", "wpctl status"]
        stdout: StdioCollector {
            onStreamFinished: {
                sys.audioOutputs = sys.parseWpctl(this.text, "Sinks");
                sys.audioInputs = sys.parseWpctl(this.text, "Sources");
            }
        }
    }

    Process {
        id: outVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { onStreamFinished: {
            const v = sys.parseVolume(this.text);
            if (v !== null) sys.outVolume = v;
            sys.outMuted = this.text.indexOf("[MUTED]") >= 0;
        } }
    }

    Process {
        id: inVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector { onStreamFinished: {
            const v = sys.parseVolume(this.text);
            if (v !== null) sys.inVolume = v;
            sys.inMuted = this.text.indexOf("[MUTED]") >= 0;
        } }
    }

    Process {
        id: wifiList
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY,RATE,FREQ", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector { onStreamFinished: sys.parseNmcli(this.text) }
    }
    Process {
        id: wifiScan
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY,RATE,FREQ", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                sys.parseNmcli(this.text);
                sys.wifiScanning = false;
            }
        }
    }
    function scanWifi() {
        if (!sys.wifiOn || wifiScan.running) return;
        sys.wifiScanning = true;
        wifiScan.running = true;
    }
    Timer {
        id: wifiScanTimeout
        interval: 12000
        onTriggered: sys.wifiScanning = false
    }
    onWifiScanningChanged: {
        if (wifiScanning) wifiScanTimeout.restart();
        else wifiScanTimeout.stop();
    }

    Process {
        id: wifiRadio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: sys.wifiOn = this.text.trim() === "enabled" }
    }

    Process {
        id: btPower
        command: ["sh", "-c", "bluetoothctl show | awk '/Powered:/ {print $2}'"]
        stdout: StdioCollector { onStreamFinished: sys.btOn = this.text.trim() === "yes" }
    }

    Process {
        id: btDevs
        command: ["sh", "-c", "bluetoothctl devices Paired | while read -r _ mac name; do c=$(bluetoothctl info \"$mac\" | awk '/Connected:/ {print $2}'); printf '%s|%s|%s\\n' \"$mac\" \"$name\" \"$c\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                sys.btDevices = this.text.trim().split("\n").filter(l => l.length > 0).map(l => {
                    const p = l.split("|");
                    return { mac: p[0], name: p[1] || p[0], connected: p[2] === "yes" };
                });
            }
        }
    }

    Process {
        id: windowTitleProc
        command: ["sh", "-c", "niri msg --json focused-window 2>/dev/null | sed -n 's/.*\"title\":\"\\([^\"]*\\)\".*/\\1/p'"]
        stdout: StdioCollector { onStreamFinished: sys.windowTitle = this.text.trim() }
    }

    // Fast tick: CPU per-core + RAM.
    Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { statFile.reload(); memFile.reload(); loadFile.reload(); uptimeFile.reload(); }
    }
    // Slow tick: disks, temperature, audio volume, window title.
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            dfProc.running = true;
            tempProc.running = true;
            outVol.running = true;
            inVol.running = true;
            windowTitleProc.running = true;
        }
    }
    // Device lists are refreshed when a popup opens (see refreshDevices).
    function refreshDevices() {
        wpctlStatus.running = true;
        wifiList.running = true;
        wifiRadio.running = true;
        refreshWifiIp();
        btPower.running = true;
        btDevs.running = true;
    }
    Component.onCompleted: { cpuInfo.reload(); refreshDevices(); }
}
