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

  systemd.services.nvidia-device-nodes = {
    description = "Create NVIDIA device nodes";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.nvidia-modprobe ];
    script = ''
      nvidia-modprobe -c 0
      nvidia-modprobe -u
    '';
  };

  environment.systemPackages =
    (with pkgs; [
      nvidia-modprobe
      vulkan-tools
      mesa-demos
      radeontop
    ])
    ++ lib.optional (pkgs ? nvtopPackages && pkgs.nvtopPackages ? full) pkgs.nvtopPackages.full;
}
