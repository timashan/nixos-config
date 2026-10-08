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
  '';
in
{
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
