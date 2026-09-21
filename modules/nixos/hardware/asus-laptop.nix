{ lib, username, ... }:

{
  boot.kernelModules = [ "asus-armoury" ];

  services.ghelper = {
    enable = true;
    user = username;
    gpuBootService = true;
  };

  # G-Helper owns performance profiles, fans, and GPU modes on this host.
  services.power-profiles-daemon.enable = lib.mkForce false;
}
