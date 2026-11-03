{ pkgs, ... }:

{
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

  # BlueZ's AutoEnable cannot power on an adapter blocked by rfkill.
  # Clear the saved Bluetooth block once at startup, after state restoration.
  systemd.services.bluetooth-unblock = {
    description = "Clear Bluetooth software radio block";
    wantedBy = [ "bluetooth.service" ];
    before = [ "bluetooth.service" ];
    wants = [ "systemd-rfkill.service" ];
    after = [ "systemd-rfkill.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };
}
