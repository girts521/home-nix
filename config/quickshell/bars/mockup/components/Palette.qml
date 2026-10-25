pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// pywal16's generated palette is the single color source for the mockup bar.
Scope {
    id: palette
    property var wal: ({})
    readonly property var colors: wal && wal.colors ? wal.colors : ({})
    readonly property var special: wal && wal.special ? wal.special : ({})
    readonly property color bg: special.background || "#122957"
    readonly property color fg: special.foreground || "#c6cff5"
    readonly property color dark: colors.color0 || bg
    readonly property color red: colors.color1 || fg
    readonly property color green: colors.color2 || fg
    readonly property color yellow: colors.color3 || fg
    readonly property color blue: colors.color4 || fg
    readonly property color purple: colors.color5 || fg
    readonly property color cyan: colors.color6 || fg
    readonly property color light: colors.color7 || fg
    readonly property color muted: colors.color8 || fg
    readonly property color brightRed: colors.color9 || red
    readonly property color brightGreen: colors.color10 || green
    readonly property color brightYellow: colors.color11 || yellow
    readonly property color brightBlue: colors.color12 || blue
    readonly property color brightPurple: colors.color13 || purple
    readonly property color brightCyan: colors.color14 || cyan
    readonly property color bright: colors.color15 || fg
    readonly property color accent: purple
    readonly property color secondary: blue
    readonly property color warning: yellow
    readonly property color error: red
    readonly property color sky: cyan
    readonly property color emerald: green
    readonly property color subtle: muted

    function toneColor(tone) {
        if (tone === "accent" || tone === "purple") return accent;
        if (tone === "secondary" || tone === "blue") return secondary;
        if (tone === "muted") return muted;
        if (tone === "sky" || tone === "cyan") return cyan;
        if (tone === "emerald" || tone === "green") return green;
        if (tone === "warning" || tone === "yellow") return yellow;
        if (tone === "error" || tone === "red") return red;
        if (tone === "white" || tone === "bright") return bright;
        return fg;
    }

    FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: retryLoad.start()
        onLoadFailed: error => {
            console.warn("Could not load pywal palette; keeping the last valid palette:", error);
        }
        onLoaded: {
            try {
                const next = JSON.parse(text());
                if (!next.colors || !next.special || !next.special.background || !next.special.foreground)
                    throw new Error("missing colors/special palette sections");
                for (let i = 0; i < 16; i++)
                    if (typeof next.colors["color" + i] !== "string") throw new Error("missing color" + i);
                palette.wal = next;
                console.info("Loaded live pywal palette from", path);
            } catch (e) {
                console.warn("Could not load pywal palette:", e);
            }
        }
    }
    Timer { id: retryLoad; interval: 250; onTriggered: walFile.reload() }
    Component.onCompleted: walFile.reload()
}
