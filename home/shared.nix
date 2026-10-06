{ config, pkgs, ... }:

{
  # Shared across ALL hosts — this is the "single source of truth" part.
  # As you migrate tools from pacman/AUR to Nix, they land here so both
  # the Master PC and the work laptop converge to the same environment.
  home.packages = with pkgs; [
    btop
    neovim
    bat
    tree
    curl
    bluetui
    waybar
    easyeffects
    wl-clipboard
  ];

  # Example of declarative dotfiles that follow the config everywhere:
  # home.file.".config/git/config".source = ./dotfiles/gitconfig;
  # home.file.".local/bin/myscript" = {
  #   source = ./scripts/myscript;
  #   executable = true;
  # };
  #
  home.file.".local/bin/rssh" = {
  source = ../scripts/rssh;
  executable = true;
  };

  home.file.".local/bin/notes" = {
  source = ../scripts/notes;
  executable = true;
  };

  home.file.".local/bin/quicknote" = {
    source = ../scripts/quicknote;
    executable = true;
  };

  home.file.".local/bin/powermenu.sh" = {
  source = ../scripts/powermenu.sh;
  executable = true;
  };

  xdg.configFile."tmux" = {
      source = ../config/tmux;
      recursive = true;
  };

  programs.home-manager.enable = true;

  home.username = "girts";
  home.homeDirectory = "/home/girts";
  home.stateVersion = "25.05";
}
