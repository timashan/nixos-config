{
  config,
  pkgs,
  username,
  hostname,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/hardware/asus-tuf-a15-fa507nu.nix
    ../../modules/nixos/desktop-plasma.nix
    ../../modules/nixos/desktop-hyprland.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/apps.nix
  ];

  networking.hostName = hostname;

  users.users.${username} = {
    isNormalUser = true;
    description = "Timashan";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "docker"
      "libvirtd"
      "kvm"
      "adbusers"
    ];
    shell = pkgs.zsh;
  };

  # Set this to the NixOS release used for the first install.
  system.stateVersion = "26.05";
}

