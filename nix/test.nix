{
  lib,
  pkgs,
  config,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "minimal-test";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ ./service.nix ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      services.xserver.enable = true;
      services.displayManager.gdm.enable = true;
      services.displayManager.gdm.wayland = true;
      programs.sway.enable = true;
      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = "alice";

      environment.systemPackages = [ pkgs.curl ];

      users.users.alice = {
        isNormalUser = true;
        extraGroups = [ "wheel" "ydotool" ];
        packages = with pkgs; [
          (callPackage ./package.nix { })
        ];
      };

      services = {
        webremote = {
          enable = true;
          port = 8000;
        };

        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };
      security.rtkit.enable = true;
      programs.ydotool.enable = true;
    };

  testScript = ''
    machine.wait_for_open_port(8000, timeout = 120)
    output = machine.succeed("curl localhost:8000")
    assert "key-button" in output, "curl output does not contain 'key-button'"
  '';
}
