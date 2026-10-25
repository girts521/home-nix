# Bar configurations

Each subfolder here is one named bar. The goal: any bar can be selected per host
in Nix, without deleting the others.

| Name     | Path                    | Status                                   |
|----------|-------------------------|------------------------------------------|
| bar      | config/quickshell/bar   | Current working Quickshell bar (QML).    |
| mockup   | config/quickshell/bars/mockup | QML port of reference.html. Default on all hosts. Untested on live Niri. |

## Layout

- `config/quickshell/bar/` is the original bar. Kept as an alternative.
- `config/quickshell/bars/<name>/` holds one bar per folder, each with a
  `shell.qml` entry point and optional `components/`.
- `mockup/` is the QML port of `reference.html`. Its popups: CPU, RAM, Disk,
  Wi-Fi, Bluetooth, Volume (output and input), Clock, Media, Notifications.
  Real data comes from /proc, df, wpctl, nmcli, bluetoothctl and niri.
  `reference.html` stays in the folder as the design source.

## Switching bars

Both bars are always installed. `home/modules/quickshell.nix` defines the option
`home-nix.bar` (enum: `mockup` | `bar`, default `mockup`), which chooses the
active config. Per host:

    home-nix.bar = "bar";   # in home/hosts/<host>/<host>.nix

The masterpc systemd override uses `--config ${config.home-nix.bar}`, so it
follows the same choice.

## Not yet verified

The QML was written without a running Quickshell or Niri here. Before relying
on it, check on the live session:
- popups open centered under their chip and dismiss on outside click
- wpctl / nmcli / bluetoothctl output parsing
- `nix eval` / `home-manager build` on both hosts
