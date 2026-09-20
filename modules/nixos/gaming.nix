{
  config,
  lib,
  pkgs,
  ...
}:

let
  dlss5vklayer = pkgs.callPackage ../../packages/dlss5vklayer { };
  gamescopeBin = "/run/wrappers/bin/gamescope";
  steamReal = config.programs.steam.package;

  steamScopeWrapper = pkgs.writeShellScript "steam-scope-wrapper" ''
    real=${lib.escapeShellArg (lib.getExe steamReal)}
    systemd_run=${lib.escapeShellArg (lib.getExe' pkgs.systemd "systemd-run")}
    systemctl=${lib.escapeShellArg (lib.getExe' pkgs.systemd "systemctl")}
    if grep -Fq '/steam.scope' /proc/self/cgroup 2>/dev/null; then
      exec "$real" "$@"
    fi
    if "$systemctl" --user is-active --quiet steam.scope 2>/dev/null; then
      exec "$real" "$@"
    fi
    exec "$systemd_run" --user --scope --unit=steam.scope --collect --quiet -- "$real" "$@"
  '';

  # PATH wrapper only. programs.steam.package must stay pkgs.steam so the
  # NixOS module can call steam.override.
  steamScoped = pkgs.symlinkJoin {
    name = "steam-scoped";
    paths = [ steamReal ];
    passthru = steamReal.passthru or { };
    postBuild = ''
      rm -f "$out/bin/steam"
      cp ${lib.escapeShellArg steamScopeWrapper} "$out/bin/steam"
    '';
    meta = (steamReal.meta or { }) // {
      mainProgram = "steam";
      priority = -10;
    };
  };

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
      ${lib.getExe steamScoped} -tenfoot -pipewire-dmabuf
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

  # Both architecture manifests are included; the Vulkan loader selects its own.
  # Processing remains opt-in through VKLayer_DLSS5=1 for each game.
  hardware.graphics.extraPackages = [ dlss5vklayer ];
  hardware.graphics.extraPackages32 = [ dlss5vklayer ];

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  services.displayManager.sessionPackages = [ steamGamescopeSession ];

  environment.systemPackages = with pkgs; [
    dlss5vklayer
    (lib.hiPrio steamScoped)
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
