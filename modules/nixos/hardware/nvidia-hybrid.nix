{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;

    # Keeps suspend/resume and offload power behavior saner on modern laptops.
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    dynamicBoost.enable = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };

  environment.systemPackages =
    (with pkgs; [
      vulkan-tools
      mesa-demos
      radeontop
    ])
    ++ lib.optional (pkgs ? nvtopPackages && pkgs.nvtopPackages ? full) pkgs.nvtopPackages.full;
}
