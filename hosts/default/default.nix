{
  pkgs,
  username,
  hostname,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/desktop-plasma.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/apps.nix
  ];

  networking.hostName = hostname;

  users.users.${username} = {
    isNormalUser = true;
    description = "Admin";
    hashedPasswordFile = "/etc/nixos/secrets/${username}.password.hash";
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

  users.users.private = {
    isNormalUser = true;
    description = "Private";
    hashedPasswordFile = "/etc/nixos/secrets/private.password.hash";
    extraGroups = [
      "networkmanager"
      "audio"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "26.05";
}
