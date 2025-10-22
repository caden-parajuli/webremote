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
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.webremote = {
    enable = mkEnableOption "Enables the webremote service and ydotoold";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
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

    ydotoolSocket = lib.mkOption {
      default = config.environment.variables.YDOTOOL_SOCKET;
      defaultText = "Same default as ydotool NixOS service";
      description = "Path to the ydotool socket";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.webremote = {
      wantedBy = [ "graphical-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/webremote";
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.package;
        StateDirectory = "webremote";
      };
    };

    programs.ydotool.enable = lib.mkDefault true;
  };
}
