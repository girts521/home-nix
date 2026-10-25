# Bar configurations

Each subfolder here is one named bar. The goal: any bar can be selected per host
in Nix, without deleting the others.

| Name     | Path                    | Status                                   |
|----------|-------------------------|------------------------------------------|
| bar      | config/quickshell/bar   | Current working Quickshell bar (QML).    |
| mockup   | config/quickshell/bars/mockup | Design reference (HTML). Port to QML. Planned default. |

## Layout

- `config/quickshell/bar/` is the existing live config. Do not move it yet;
  `home/modules/quickshell.nix` points at it.
- `config/quickshell/bars/<name>/` holds one bar per folder. A QML bar folder
  needs a `shell.qml` (same shape as `bar/`). The `mockup` folder contains only
  `reference.html` for now, so it is not a loadable Quickshell config yet.

## Viewing the mockup reference

Open `config/quickshell/bars/mockup/reference.html` in a browser. It is a static
HTML/Tailwind-style mockup. Popups: CPU, RAM, Disk, Wi-Fi, Bluetooth, Volume
(output and input), Calendar, Media, Notifications. All data is mock data.

## Planned switching (not implemented yet)

- Both hosts (`masterpc`, `laptop`) enable the quickshell module.
- Each host selects a bar by name, e.g. `home-nix.bar = "mockup";`, set in
  `home/modules/quickshell.nix` or in the host file.
- The `mockup` bar becomes the default. `bar` stays as an alternative.
- Each selected bar is registered under `programs.quickshell.configs.<name>` and
  activated with `activeConfig`. The masterpc systemd override that runs
  `--config bar` must follow the selected name.

Implementation waits for the QML port of the mockup.
