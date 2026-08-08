{
  config,
  gpuBusIds ? { },
  pkgs,
  username,
  hostname,
  ...
}:

{
  imports = [
    ./audio.nix
    ./hardware-configuration.nix
    ./users.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/hardware/laptop.nix
    ../../modules/nixos/hardware/asus-laptop.nix
    ../../modules/nixos/hardware/nvidia-hybrid.nix
    ../../modules/nixos/desktop-plasma.nix
    ../../modules/nixos/desktop-hyprland.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/ai-agents.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/apps.nix
    ../../modules/nixos/vaultwarden.nix
    ../../modules/nixos/backups.nix
  ];

  networking.hostName = hostname;

  # This FA507NU is hybrid graphics: AMD Radeon iGPU plus RTX 4050 Laptop dGPU.
  # Confirm bus IDs after install with: lspci | grep -E "VGA|3D|Display"
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  hardware.nvidia.prime = {
    amdgpuBusId = gpuBusIds.amdgpu;
    nvidiaBusId = gpuBusIds.nvidia;
  };

  fileSystems."/run/media/${username}/New Volume" = {
    device = "/dev/disk/by-uuid/EA60D43260D4076B";
    fsType = "ntfs3";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "windows_names"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /run/media 0755 root root -"
    "d /run/media/${username} 0755 ${username} users -"
  ];

  # Set this to the NixOS release used for the first install.
  system.stateVersion = "26.05";
}
