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
    let
      webremotePackage = pkgs.callPackage ./package.nix { };
    in
    {
      imports = [ ./service.nix ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      programs.sway.enable = true;

      # Launch sway on boot
      services.xserver.enable = lib.mkForce false;
      services.displayManager.gdm.enable = lib.mkForce false;
      services.getty = {
        autologinUser = "alice";
        autologinOnce = true;
      };
      environment.loginShellInit = ''
        [[ "$(tty)" == /dev/tty1 ]] && sway
      '';

      # services.displayManager.gdm.enable = true;
      # services.displayManager.autoLogin.enable = true;
      # services.displayManager.autoLogin.user = "alice";

      environment.systemPackages = [
        pkgs.curl
        pkgs.pipewire
        webremotePackage
      ];

      users.users.alice = {
        initialPassword = "password";
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "ydotool"
        ];
        packages = with pkgs; [
          (callPackage ./package.nix { })
        ];
      };

      services = {
        webremote = {
          enable = true;
          usePipewire = true;

          port = 8000;

          settings.window_manager = "sway";
        };

        pipewire = {
          enable = true;
          wireplumber.enable = true;
          audio.enable = true;
          socketActivation = true;

          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };

      systemd.user.services.webremote.wantedBy = lib.mkForce [];
      systemd.user.services.webremote.after = lib.mkForce [];

      security.rtkit.enable = true;
      programs.ydotool.enable = true;
    };

  testScript = ''
    import time
    machine.start()
    machine.wait_for_unit("graphical.target")
    time.sleep(5)

    # Find sway socket
    swaysock = ""
    files = machine.succeed("ls /run/user/1000").split('\n')
    for filename in files:
        print(filename)
        if filename.startswith("sway-ipc"):
            swaysock = "/run/user/1000/" + filename
            break
    assert swaysock != "", "Could not find swaysock"

    # Force pipewire-pulse to create the cookie file
    machine.succeed("swaymsg -s {} exec 'pactl info'".format(swaysock))

    # Start WebRemote
    print("Starting WebRemote")
    machine.systemctl("start webremote", "alice")
    time.sleep(3)
    print(machine.systemctl("status webremote", "alice")[1])
    machine.wait_for_open_port(8000, timeout = 15)

    # Verify the page is up
    output = machine.succeed("curl localhost:8000")
    assert "key-button" in output, "curl output does not contain 'key-button'"
  '';
}
