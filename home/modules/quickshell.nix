{ config, lib, pkgs, ... }:

let
  calendarPython = pkgs.python3.withPackages (ps: [
    ps.icalendar
    ps."recurring-ical-events"
  ]);
  calendarEvents = pkgs.writeShellScriptBin "qs-calendar-events" ''
    exec ${calendarPython}/bin/python3 ${../../config/quickshell/calendar/events.py} "$@"
  '';
in
{
  # Which bar runs on this host. Both bars are always installed; this picks one.
  # Override per host, e.g. in home/hosts/<host>/<host>.nix:
  #   home-nix.bar = "bar";
  options.home-nix.bar = lib.mkOption {
    type = lib.types.enum [ "mockup" "bar" ];
    default = "mockup";
    description = "Quickshell bar configuration to run on this host.";
  };

  config = {
    programs.quickshell = {
      enable = true;
      configs = {
        mockup = ../../config/quickshell/bars/mockup;
        bar = ../../config/quickshell/bar;
      };
      activeConfig = config.home-nix.bar;
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };

    home.packages = [ calendarEvents pkgs.cava pkgs.python3 ];
  };
}
