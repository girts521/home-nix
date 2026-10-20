{ pkgs, ... }:

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
  programs.quickshell = {
    enable = true;
    configs.bar = ../../config/quickshell/bar;
    activeConfig = "bar";
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };

  home.packages = [ calendarEvents ];
}
