{ pkgs, ... }:

{
  boot.kernelModules = [ "asus-armoury" ];

  services.asusd.enable = true;

  # asusd's upstream unit has ReadWritePaths=/etc/asusd/, and systemd rejects
  # the service before ExecStart when that directory is missing.
  systemd.tmpfiles.rules = [
    "d /etc/asusd 0755 root root -"
  ];

  # Useful on ASUS hybrid laptops for Integrated, Hybrid, and dGPU modes when
  # the firmware supports them.
  services.supergfxd.enable = true;

  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
  ];
}
