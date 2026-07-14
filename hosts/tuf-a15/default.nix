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
  boot.kernelPackages = pkgs.linuxPackages_7_0;
  hardware.nvidia.prime = {
    amdgpuBusId = gpuBusIds.amdgpu;
    nvidiaBusId = gpuBusIds.nvidia;
  };

  # Set this to the NixOS release used for the first install.
  system.stateVersion = "26.05";
}
