# Work laptop — per-host extras.
# Whatever YOU only want here (work-specific tooling / auth / etc) goes
# in this file only, so it never bleeds onto the Master PC.
{ config, pkgs, ... }:

{
  # e.g. home.packages = [ pkgs.zoom-us pkgs.slack ... ];
  targets.genericLinux.enable = true;

  home.file.".local/bin/disk_usage" = {
    source = ./scripts/disk_usage;
    executable = true;
  };

    home.file.".local/bin/mcli" = {
    source = ./scripts/mcli;
    executable = true;
  };
  
  home.file.".local/bin/rfx" = {
  source = ./scripts/rfx;
  executable = true;
  };

  home.file.".local/bin/search_notes.sh" = {
  source = ./scripts/search_notes.sh;
  executable = true;
  };

}
