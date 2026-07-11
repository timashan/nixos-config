{
  lib,
  pkgs,
  username,
  ...
}:

{
  users.users.${username} = {
    isNormalUser = true;
    description = lib.toSentenceCase username;
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
  home-manager.users.${username} = {
    imports = [ ../../home/main/home.nix ];
    home.username = username;
    home.homeDirectory = "/home/${username}";
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
  home-manager.users.private = import ../../home/private/home.nix;
}
