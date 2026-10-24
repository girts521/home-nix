# Master PC (.150) — per-host extras.
# i9 + 128GB RAM + RTX 4090, Arch + Ollama, eno2 on the homelab net.
# Things here are Master-PC-only, so they DON'T install on the laptop.
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    lidarr
    python313Packages.syncedlyrics
    sabnzbd
    spotdl
    vesktop
  ];
  # e.g. home.packages = [ pkgs.ollama ... ];
  # e.g. GPU / machine-specific tooling goes here, not in shared.nix

  # Nix-built quickshell can't see the host NVIDIA EGL driver -> wrap it.
  # nixGL auto-detects the driver version at runtime.
  systemd.user.services.quickshell.Service.ExecStart = lib.mkForce
    "${pkgs.nixgl.auto.nixGLNvidia}/bin/nixGLNvidia ${pkgs.quickshell}/bin/quickshell --config bar";
}
