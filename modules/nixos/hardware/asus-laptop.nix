{
  config,
  lib,
  username,
  ...
}:

{
  # The pinned 6.12 kernel exposes the existing asus-wmi controls, but does
  # not ship the armoury driver. Request it only on kernels that include it.
  boot.kernelModules = lib.optionals (config.boot.kernelPackages.kernel.kernelAtLeast "6.19") [
    "asus-armoury"
  ];

  services.ghelper = {
    enable = true;
    user = username;
    gpuBootService = true;
  };

  home-manager.users.${username}.imports = [ ../../home-manager/ghelper.nix ];

  # G-Helper owns performance profiles, fans, and GPU modes on this host.
  services.power-profiles-daemon.enable = lib.mkForce false;
}
