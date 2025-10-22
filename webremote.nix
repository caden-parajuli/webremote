{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.webremote;
  defaultUser = "webremote";
  defaultGroup = "webremote";
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.webremote = {
    enable = mkEnableOption "webremote service";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix {};
    };

    user = lib.mkOption {
      default = defaultUser;
      description = "User bookstack runs as";
      type = lib.types.str;
    };

    group = lib.mkOption {
      default = config.services.ydotool.group;
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

  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {
    systemd.services.hello = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.hello}/bin/hello -g'Hello, ${escapeShellArg cfg.greeter}!'";
    };
  };
}
