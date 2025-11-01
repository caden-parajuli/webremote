{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.services.webremote;
  defaultUser = "webremote";
  defaultGroup = "ydotool";
in
{
  options.services.webremote = {
    enable = mkEnableOption "Enables the webremote service and ydotoold";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
    };

    ydotoolPackage = mkOption {
      type = types.package;
      default = pkgs.ydotool;
    };

    user = lib.mkOption {
      default = defaultUser;
      description = "User webremote runs as";
      type = lib.types.str;
    };

    group = lib.mkOption {
      default = config.programs.ydotool.group;
      defaultText = "The same group as ydotool";
      description = "Group webremote runs as. Must have write permission to the ydotool socket";
      type = lib.types.str;
    };

    interface = lib.mkOption {
      default = "0.0.0.0";
      defaultText = "All interfaces";
      description = "The interface the webserver listens on";
      type = lib.types.str;
    };

    port = lib.mkOption {
      default = 8008;
      description = "The port the webserver listens on";
      type = lib.types.int;
    };

    ydotoolSocket = lib.mkOption {
      default = "/run/ydotoold/socket";
      defaultText = "Same default as ydotool NixOS service";
      description = "Sets the YDOTOOL_SOCKET environment variable. This is also used by the ydotool NixOS service.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.webremote = {
      wantedBy = [ "graphical-user.target" ];
      after = [
        "multi-user.target"
        "pipewire-pulse.service"
      ];
      wants = [
        "ydotoold.service"
        "pipewire-pulse.service"
        "network-online.target"
      ];
      path = [ cfg.ydotoolPackage ];
      environment = {
        YDOTOOL_SOCKET = cfg.ydotoolSocket;
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/webremote --interface ${cfg.interface} --port ${toString cfg.port}";
        WorkingDirectory = cfg.package;
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "webremote";
      };
    };
    users.users = lib.mkIf (cfg.user == "webremote") {
      webremote = {
        description = "Webremote service";
        home = "/var/lib/webremote";
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "webremote") {
      webremote = { };
    };

    programs.ydotool.enable = true;
    environment.variables.YDOTOOL_SOCKET = lib.mkForce cfg.ydotoolSocket;
  };
}
