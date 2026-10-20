# Home Manager: Niri Quickshell bar

This bundle copies the **working Niri bar** from `quickshell-niri-waybar-fixed/shell.qml`
into an example Home Manager host-module layout. It does not change Niri or Waybar.

## Add to your home-nix flake repo

From the directory containing `flake.nix`:

```sh
cd ~/dev/home-nix
unzip ~/Downloads/home-nix-quickshell-bar.zip -d .
```

Add the module to the *laptop* Home Manager configuration's existing `imports` list:

```nix
imports = [
  # existing imports...
  ./quickshell-bar.nix
];
```

The import path is relative to the Nix file holding the `imports` list. The
example assumes it lives in `hosts/laptop/`. If that is not the case, adjust
accordingly.

Flakes only see tracked or staged repository files, so:

```sh
git add hosts/laptop/quickshell-bar.nix hosts/laptop/quickshell/bar/shell.qml
home-manager switch --flake .#laptop
```

Test it (stop the existing demo with Ctrl+C before running this):

```sh
qs -c bar
```

## Autostart after testing

In the **existing, Home Manager-managed** Niri config.kdl, add:

```kdl
spawn-at-startup "qs" "-c" "bar"
```

Remove or comment out the existing `spawn-at-startup "waybar"` **only once**
you intend to switch permanently. Do not enable `programs.quickshell.systemd`
if using Niri autostart, or Quickshell may be started twice.

The Quickshell bar reserves 36px of screen space and starts at the top of every
monitor; both settings are in `shell.qml`. Its colors continue to load from
`~/.cache/wal/colors.json`.

## Working on QML

Home Manager installs QML via symlinks to immutable files in `/nix/store`.
Edit the file **in the repo**, not under `~/.config/quickshell/bar`, and re-run
`home-manager switch --flake .#laptop` to deploy the change.

To iterate with faster hot reload, stop the deployed bar, and run directly from
the mutable project directory:

```sh
qs -p ~/dev/home-nix/hosts/laptop/quickshell/bar
```

Afterwards switch back to `qs -c bar`. The given module only affects `laptop`.
