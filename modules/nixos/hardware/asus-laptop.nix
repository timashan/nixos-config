{ lib, username, ... }:

{
  boot.kernelModules = [ "asus-armoury" ];

  services.ghelper = {
    enable = true;
    user = username;
    gpuBootService = true;
  };

  home-manager.users.${username}.imports = [ ../../home-manager/ghelper.nix ];

  # G-Helper owns performance profiles, fans, and GPU modes on this host.
  services.power-profiles-daemon.enable = lib.mkForce false;
}
