{ config, pkgs, ... }:

{
  # Shared across ALL hosts — this is the "single source of truth" part.
  # As you migrate tools from pacman/AUR to Nix, they land here so both
  # the Master PC and the work laptop converge to the same environment.
  home.packages = [
    # start small, real tools you actually use (3-6, not a migration)
  ];

  # Example of declarative dotfiles that follow the config everywhere:
  # home.file.".config/git/config".source = ./dotfiles/gitconfig;
  # home.file.".local/bin/myscript" = {
  #   source = ./scripts/myscript;
  #   executable = true;
  # };

  programs.home-manager.enable = true;

  home.username = "girts";
  home.homeDirectory = "/home/girts";
  home.stateVersion = "25.05";
}
