{ ... }:

{
  programs.quickshell = {
    enable = true;

    configs.bar = ../../config/quickshell/bar;
    activeConfig = "bar";

    systemd.enable = false;
  };
}
