{
  username,
  hostname,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/desktop-plasma.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/ai-agents.nix
    ../../modules/nixos/apps.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = "26.05";
}
