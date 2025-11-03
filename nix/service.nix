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
  defaultGroup = config.programs.ydotool.group;
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
    systemd.user.services.webremote = {
      wantedBy = [ "default.target" ];
      after = [
        "pipewire-pulse.service"
        "network-online.target"
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
        StateDirectory = "webremote";
      };
    };

    programs.ydotool.enable = true;
    environment.variables.YDOTOOL_SOCKET = lib.mkForce cfg.ydotoolSocket;
  };
}
