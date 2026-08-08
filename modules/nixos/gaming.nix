{
  config,
  lib,
  pkgs,
  ...
}:

let
  gamescopeBin = "/run/wrappers/bin/gamescope";

  steamGamescope = pkgs.writeShellScriptBin "steam-gamescope-session" ''
    set -eu

    log="$HOME/.local/state/steam-gamescope-session.log"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$log")"
    exec >"$log" 2>&1

    echo "[$(${pkgs.coreutils}/bin/date --iso-8601=seconds)] starting Steam gamescope session"
    cd "$HOME"

    backlight_device="nvidia_wmi_ec_backlight"
    backlight_path="/sys/class/backlight/$backlight_device/brightness"
    previous_brightness=""

    restore_backlight() {
      if [ -n "$previous_brightness" ]; then
        echo "restoring $backlight_device brightness to $previous_brightness"
        ${pkgs.brightnessctl}/bin/brightnessctl --device="$backlight_device" set "$previous_brightness" >/dev/null 2>&1 || true
      fi
    }
    trap restore_backlight EXIT HUP INT TERM

    hdmi_connected=0
    for status_path in /sys/class/drm/card*-HDMI-A-1/status; do
      [ -e "$status_path" ] || continue
      if [ "$(${pkgs.coreutils}/bin/cat "$status_path")" = "connected" ]; then
        hdmi_connected=1
        break
      fi
    done

    if [ "$hdmi_connected" = 1 ] && [ -r "$backlight_path" ]; then
      previous_brightness="$(${pkgs.coreutils}/bin/cat "$backlight_path")"
      echo "HDMI connected; dimming $backlight_device from $previous_brightness"
      ${pkgs.brightnessctl}/bin/brightnessctl --device="$backlight_device" set 0 >/dev/null 2>&1 || true
    fi

    ${gamescopeBin} \
      --steam \
      --prefer-vk-device 10de:28e1 \
      --prefer-output HDMI-A-1,eDP-1 \
      -- \
      ${pkgs.util-linux}/bin/setpriv \
      --inh-caps -all \
      --ambient-caps -all \
      -- \
      ${lib.getExe config.programs.steam.package} -tenfoot -pipewire-dmabuf
  '';

  steamGamescopeSession =
    (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
      [Desktop Entry]
      Name=Steam
      Comment=A digital distribution platform
      Exec=${lib.getExe steamGamescope}
      Type=Application
    '').overrideAttrs
      (_: {
        passthru.providedSessions = [ "steam" ];
      });
in
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = false;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  hardware.steam-hardware.enable = true;

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  services.displayManager.sessionPackages = [ steamGamescopeSession ];

  environment.systemPackages = with pkgs; [
    wineWow64Packages.stable
    winetricks
    protontricks
    protonup-qt
    lutris
    heroic
    bottles
    mangohud
    goverlay
    gamescope
    gamemode
  ];
}
