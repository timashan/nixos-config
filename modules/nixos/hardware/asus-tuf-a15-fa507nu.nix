{
  config,
  lib,
  pkgs,
  ...
}:

{
  # This FA507NU is hybrid graphics: AMD Radeon iGPU plus RTX 4050 Laptop dGPU.
  # Windows device paths suggest these Linux PRIME bus IDs, but confirm after
  # install with:
  #   lspci | grep -E "VGA|3D|Display"
  boot.kernelPackages = pkgs.linuxPackages_7_0;
  boot.kernelModules = [ "asus-armoury" ];

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

    # The RTX 4050 supports NVIDIA's open kernel module.
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

      # Update these if Linux lspci reports different bus numbers.
      amdgpuBusId = "PCI:4:0:0";
      nvidiaBusId = "PCI:9:0:0";
    };
  };

  services.asusd = {
    enable = true;
  };

  # asusd's upstream unit has ReadWritePaths=/etc/asusd/, and systemd rejects
  # the service before ExecStart when that directory is missing.
  systemd.tmpfiles.rules = [
    "d /etc/asusd 0755 root root -"
  ];

  # supergfxctl is useful on ASUS hybrid laptops for Integrated, Hybrid, and
  # dGPU modes when the firmware supports them.
  services.supergfxd.enable = true;

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  powerManagement.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "poweroff";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
    };
  };

  environment.systemPackages =
    (with pkgs; [
      asusctl
      supergfxctl
      vulkan-tools
      mesa-demos
      radeontop
    ])
    ++ lib.optional (pkgs ? nvtopPackages && pkgs.nvtopPackages ? full) pkgs.nvtopPackages.full;
}
