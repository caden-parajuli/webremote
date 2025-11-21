{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.services.webremote;

  appConfigFormat = pkgs.formats.json { };
  appConfigFile = appConfigFormat.generate "config.json5" cfg.settings;
  pulseService = if cfg.usePipewire then "pipewire-pulse.service" else "pulseaudio.service";
  wmPaths =
    if cfg.settings.window_manager == "hyprland" then [ config.programs.hyprland.package ] else [ ];
in
{
  options.services.webremote = {
    enable = mkEnableOption "Enables the webremote service and ydotoold";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
    };

    usePipewire = mkOption {
      type = types.bool;
      default = true;
      description = "Whether the PulseAudio daemon runs through Pipewire. If true, WebRemote will depend on the pipewire-pulse daemon. Otherwise it will depend on the pulseaudio daemon";
    };

    ydotoolPackage = mkOption {
      type = types.package;
      default = pkgs.ydotool;
    };

    interface = lib.mkOption {
      type = types.str;
      default = "0.0.0.0";
      defaultText = "All interfaces";
      description = "The interface the webserver listens on";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8008;
      description = "The port the webserver listens on";
    };

    ydotoolSocket = lib.mkOption {
      type = types.path;
      default = "/run/ydotoold/socket";
      defaultText = "Same default as ydotool NixOS service";
      description = "Sets the YDOTOOL_SOCKET environment variable. This is also used by the ydotool NixOS service.";
    };

    settings =
      let
        appOptions = with lib.types; {
          options = {
            name = mkOption {
              type = str;
            };
            pretty_name = mkOption {
              type = nullOr str;
              default = null;
            };
            launch_command = mkOption {
              type = str;
            };
            icon_path = mkOption {
              type = nullOr str;
              default = null;
            };
            default_workspace = mkOption {
              type = nullOr int;
              default = null;
            };
          };
        };
        configOpts = with lib.types; {
          options = {
            window_manager = mkOption {
              # todo: enum
              type = enum [
                "sway"
                "hyprland"
              ];
              default = "sway";
            };
            apps = mkOption {
              type = with lib.types; listOf (submodule appOptions);
              default = [];
              example = [
                {
                  name = "kodi";
                  pretty_name = "Kodi";
                  launch_command = "kodi";
                  default_workspace = 1;
                }
                {
                  name = "youtube";
                  pretty_name = "YouTube";
                  launch_command = "VacuumTube";
                  default_workspace = 2;
                }
              ];
            };
          };
        };
      in
      lib.mkOption {
        type = with lib.types; submodule configOpts;
        default = {
          window_manager = "sway";
          apps = [
            {
              name = "kodi";
              pretty_name = "Kodi";
              launch_command = "kodi";
              default_workspace = 1;
            }
            {
              name = "youtube";
              pretty_name = "YouTube";
              launch_command = "VacuumTube";
              default_workspace = 2;
            }
          ];
        };
      };
  };

  config = mkIf cfg.enable {
    systemd.user.services.webremote = {
      wantedBy = [ "default.target" ];
      after = [
        pulseService
        "network-online.target"
      ];
      wants = [
        "ydotoold.service"
        pulseService
        "network-online.target"
      ];
      path = [ cfg.ydotoolPackage ] ++ wmPaths;
      environment = {
        YDOTOOL_SOCKET = cfg.ydotoolSocket;
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/webremote --interface ${cfg.interface} --port ${toString cfg.port} --config ${appConfigFile}";
        WorkingDirectory = cfg.package;
        Restart = "on-failure";
        StateDirectory = "webremote";
      };
    };

    programs.ydotool.enable = true;
    environment.variables.YDOTOOL_SOCKET = lib.mkForce cfg.ydotoolSocket;
  };
}
