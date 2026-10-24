# Master PC (.150) — per-host extras.
# i9 + 128GB RAM + RTX 4090, Arch + Ollama, eno2 on the homelab net.
# Things here are Master-PC-only, so they DON'T install on the laptop.
{ config, pkgs, lib, inputs, ... }:

let
  # Keep this in sync with `nvidia-smi --query-gpu=driver_version --format=csv,noheader`.
  # Pinning the version avoids nixGL's auto-detection relying on builtins.currentTime
  # and /proc during evaluation (which can produce a null version under Nix 2.34).
  nvidiaDriverVersion = "615.71.09";
  nixgl = import (inputs.nixgl.outPath + "/default.nix") {
    # nixGL's package expression uses the older NVIDIA package API from its
    # own locked nixpkgs; passing the root package set breaks at `kernel = null`.
    pkgs = import inputs.nixgl.inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    nvidiaVersion = nvidiaDriverVersion;
    enable32bits = false;
    enableIntelX86Extensions = false;
  };
in
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

  # Nix-built Quickshell needs the host NVIDIA EGL/OpenGL stack on this machine.
  # nixGL auto-detects the installed driver; keep this override host-specific.
  systemd.user.services.quickshell.Service.ExecStart = lib.mkForce
    "${nixgl.nixGLNvidia}/bin/nixGLNvidia-${nvidiaDriverVersion} ${pkgs.quickshell}/bin/quickshell --config bar";
}
