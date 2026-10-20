{
  config,
  lib,
  pkgs,
  ...
}:

let
  defaultConfig = pkgs.writeText "herdr-default-config.toml" ''
    [keys]
    prefix = "ctrl+a"

    [ui.toast]
    delivery = "system"
  '';

  soundVolumeControl = pkgs.writeShellScript "herdr-sound-volume" ''
    # Keep a mixer slider for the Music role used by Herdr's pw-play chimes.
    exec ${pkgs.pipewire}/bin/pw-play \
      --raw --format=s16 --rate=48000 --channels=2 \
      --properties='{ application.name = "Herdr" media.name = "Completion sound volume" media.role = "Music" }' \
      /dev/zero
  '';
in
{
  systemd.user.services.herdr-sound-volume = {
    Unit = {
      Description = "Keep Herdr sound volume visible in the audio mixer";
      After = [ "pipewire.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${soundVolumeControl}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Herdr saves onboarding and UI preferences in this file, so it must be writable.
  home.activation.herdrConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    configDir=${lib.escapeShellArg "${config.xdg.configHome}/herdr"}
    configFile="$configDir/config.toml"
    run mkdir -p "$configDir"

    if [ -L "$configFile" ]; then
      case "$(readlink -f "$configFile")" in
        /nix/store/*)
          run install -m 600 "$configFile" "$configFile.writable"
          run mv -f "$configFile.writable" "$configFile"
          ;;
      esac
    fi

    if [ ! -e "$configFile" ]; then
      run install -m 600 ${defaultConfig} "$configFile"
    fi
  '';
}
