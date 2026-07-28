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
    # The open kernel module with fine-grained runtime PM has repeatedly
    # soft-locked in nvidia-modeset after s2idle resume on this FA507NU.
    open = false;
    # 595.71.05 still soft-locks in nvidia-modeset after resume/fullscreen.
    # Keep proprietary PRIME offload, but use the older 580 branch and avoid GSP.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    gsp.enable = false;
    nvidiaSettings = true;

    # Keep NVIDIA's suspend/resume hooks, but avoid aggressive dGPU runtime
    # power switching while preserving PRIME offload.
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    dynamicBoost.enable = false;

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
