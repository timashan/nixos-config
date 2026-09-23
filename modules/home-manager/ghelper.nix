{
  config,
  lib,
  pkgs,
  ...
}:

let
  launchOnDemand = pkgs.writeShellScript "ghelper-on-demand" ''
    # G-Helper handles the ROG button itself once running. Avoid a second
    # instance or a second toggle from the compositor's key binding.
    if ! ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -x ghelper >/dev/null; then
      exec /run/current-system/sw/bin/ghelper
    fi
  '';

  applyPreferences = pkgs.writeShellScript "ghelper-preferences" ''
    set -euo pipefail
    settingsFile="$1"
    settingsDir="$(${pkgs.coreutils}/bin/dirname "$settingsFile")"
    ${pkgs.coreutils}/bin/mkdir -p "$settingsDir"
    tempFile="$(${pkgs.coreutils}/bin/mktemp "$settingsDir/.config.json.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$tempFile"' EXIT

    inputFile="$settingsFile"
    if [ ! -e "$inputFile" ]; then
      inputFile="${pkgs.writeText "ghelper-empty-config.json" "{}"}"
    fi

    ${pkgs.jq}/bin/jq -e '
      if type == "object" then
        . + {autostart: 0, silent_start: 0, skip_update_prompt: 1}
      else
        error("G-Helper config must be a JSON object")
      end
    ' "$inputFile" > "$tempFile"
    ${pkgs.coreutils}/bin/mv "$tempFile" "$settingsFile"
    # Remove the existing login launcher without requiring an app launch first.
    ${pkgs.coreutils}/bin/rm -f "$2"
  '';
in
{
  xdg.configFile."caelestia/hypr-user.lua".text = lib.mkAfter ''
    -- ASUS WMI Armoury Crate button: scan 0x38 -> KEY_PROG3.
    hl.bind("XF86Launch3", hl.dsp.exec_cmd("${launchOnDemand}"))
  '';

  # G-Helper saves hardware preferences here, so merge into a writable file
  # instead of replacing the complete configuration with a store symlink.
  home.activation.ghelperPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${applyPreferences} "${config.xdg.configHome}/ghelper/config.json" \
      "${config.xdg.configHome}/autostart/ghelper.desktop"
  '';
}
