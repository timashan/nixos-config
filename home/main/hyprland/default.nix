{
  config,
  lib,
  pkgs,
  caelestia-dots,
  ...
}:

let
  home = config.home.homeDirectory;
  dots = caelestia-dots;
  vscodeSettings = ../vscode/settings.json;

  cfg = path: {
    source = path;
    force = true;
  };

  cfgDir = path: {
    source = path;
    recursive = true;
    force = true;
  };

  gsettings = lib.getExe' pkgs.glib "gsettings";
  dbusUpdate = lib.getExe' pkgs.dbus "dbus-update-activation-environment";
  systemctl = lib.getExe' pkgs.systemd "systemctl";

  patchedExecs =
    lib.concatStringsSep "\n" (
      lib.filter
        (
          line:
          !(lib.hasInfix "gammastep" line)
          && !(lib.hasInfix "geoclue-2.0/demos/agent" line)
          && !(lib.hasInfix "Location provider and night light" line)
        )
        (
          lib.splitString "\n" (
            lib.replaceStrings
              [
                "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
                "gsettings set"
                "caelestia shell -d"
              ]
              [
                "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
                "${gsettings} set"
                "env QT_QPA_PLATFORMTHEME=qtengine caelestia shell -d"
              ]
              (lib.readFile "${dots}/hypr/hyprland/execs.lua")
          )
        )
    )
    + ''

      -- Keep DBus/systemd-launched apps on KDE's Qt platform theme.
      -- Import Wayland session env so xdg-desktop-portal-hyprland can screencast;
      -- restart only the Hyprland portal impl so the main portal (Settings/KDE) stays up.
      hl.exec_cmd("${systemctl} --user set-environment QT_QPA_PLATFORMTHEME=kde 'QT_QPA_PLATFORM=wayland;xcb' GDK_BACKEND=wayland,x11 XDG_MENU_PREFIX=plasma- XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland XDG_SESSION_DESKTOP=Hyprland")
      hl.exec_cmd("${systemctl} --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
      hl.exec_cmd("${dbusUpdate} --systemd WAYLAND_DISPLAY QT_QPA_PLATFORMTHEME=kde 'QT_QPA_PLATFORM=wayland;xcb' GDK_BACKEND=wayland,x11 XDG_MENU_PREFIX=plasma- XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland XDG_SESSION_DESKTOP=Hyprland")
      hl.exec_cmd("${systemctl} --user restart xdg-desktop-portal-hyprland.service")

      -- Sync toolkit settings for native apps without repainting apps during startup.
      hl.exec_cmd("CAELESTIA_SYNC_NOTIFY=0 caelestia-sync-gtk-settings")
    '';

  nixosBuiltinLogo = pkgs.writeText "fastfetch-nixos-builtin-logo.txt" (
    lib.concatStringsSep "\n" [
      "$1          NIXO       $2NIXOS    NIXO"
      "$1          NIXOS       $2NIXOS  NIXON"
      "$1           NIXOS       $2NIXOSNIXON"
      "$1            NIXOS       $2NIXOSNIX"
      "$1     NIXOSNIXONIXOSNIXON $2NIXOSN     $1NI"
      "$1    NIXOSNIXONIXOSNIXONIX $2NIXOS    $1NIXO"
      "$2           NIXOS           NIXON  $1NIXOS"
      "$2          NIXOS             NIXO $1NIXOS"
      "$2         NIXOS               NI $1NIXOS"
      "$2NIXOSNIXONIXO                  $1NIXOSNIXONIX"
      "$2NIXOSNIXONIX                  $1NIXOSNIXONIXO"
      "$2      NIXOS $1NI               XOSNI"
      "$2     NIXOS $1NIXO             SNIXO"
      "$2    NIXOS  $1NIXOS           NIXON"
      "$2    NIXO    $1NIXOS $2NIXOSNIXONIXOSNIXONI"
      "$2     NI     $1NIXOSN $2NIXOSNIXONIXOSNIXO"
      "$1           NIXOSNIX         $2NIXOS"
      "$1          NIXOSNIXON         $2NIXOS"
      "$1         NIXOS  NIXON         $2NIXOS"
      "$1         NIXO    SNIXO         $2NIXO"
    ]
  );

  fastfetchConfig = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "file",
        "source": "${nixosBuiltinLogo}",
        "color": {
          "1": "#d69bb3",
          "2": "#a99ad7",
          "3": "#d69bb3",
          "4": "#a99ad7",
          "5": "#d69bb3",
          "6": "#a99ad7"
        }
      },
      "display": {
        "separator": ": ",
        "color": "#cbbbe8"
      },
      "modules": [
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "display",
        "de",
        "wm",
        "wmtheme",
        "theme",
        "icons",
        "font",
        "cursor",
        "terminal",
        "terminalfont",
        "cpu",
        "gpu",
        "memory",
        "swap",
        "disk",
        "localip",
        "locale",
        "break",
        "colors"
      ]
    }
  '';

  hyprlandModuleFiles = lib.filter (
    name:
    !(builtins.elem name [
      "env.lua"
      "execs.lua"
    ])
  ) (builtins.attrNames (builtins.readDir "${dots}/hypr/hyprland"));

  hyprlandModuleConfig = lib.listToAttrs (
    map (name: {
      name = "hypr/hyprland/${name}";
      value = cfg "${dots}/hypr/hyprland/${name}";
    }) hyprlandModuleFiles
  );

  hyprmonProfile = pkgs.writeShellScriptBin "hyprmon-profile" ''
    set -euo pipefail

    profile="''${1:?usage: hyprmon-profile <internal|external|extend|extend-reverse>}"
    case "$profile" in
      internal|external|extend|extend-reverse) ;;
      *)
        echo "usage: hyprmon-profile <internal|external|extend|extend-reverse>" >&2
        exit 1
        ;;
    esac

    hypr_dir="${home}/.config/hypr"
    monitors_lua="$hypr_dir/hyprmon.lua"
    nwg_monitors_lua="$hypr_dir/monitors.lua"
    mkdir -p "$hypr_dir"
    rm -f "$nwg_monitors_lua"

    monitors_json=$(${pkgs.hyprland}/bin/hyprctl -j monitors all)
    internal=$(echo "$monitors_json" | ${pkgs.jq}/bin/jq -r '
      .[] | select(.name | startswith("eDP-")) | .name' | head -1)
    external=$(echo "$monitors_json" | ${pkgs.jq}/bin/jq -r --arg internal "$internal" '
      .[] | select(.name != $internal) | .name' | head -1)
    internal_width=$(echo "$monitors_json" | ${pkgs.jq}/bin/jq -r --arg internal "$internal" '
      .[] | select(.name == $internal) |
      if (.width // 0) > 0 then
        .width
      else
        ((.availableModes // [])
          | map(split("x")[0] | tonumber?)
          | max // 0)
      end' | head -1)
    external_width=$(echo "$monitors_json" | ${pkgs.jq}/bin/jq -r --arg external "$external" '
      .[] | select(.name == $external) |
      if (.width // 0) > 0 then
        .width
      else
        ((.availableModes // [])
          | map(
              select(test("^[0-9]+x[0-9]+@[0-9.]+Hz$"))
              | capture("^(?<width>[0-9]+)x(?<height>[0-9]+)@(?<refresh>[0-9.]+)Hz$")
              | .width as $width
              | .height as $height
              | .refresh as $refresh
              | {
                  width: ($width | tonumber),
                  pixels: (($width | tonumber) * ($height | tonumber)),
                  refresh: ($refresh | tonumber)
                }
            )
          | sort_by(.pixels, .refresh)
          | last.width) // 0
      end' | head -1)
    external_mode=$(echo "$monitors_json" | ${pkgs.jq}/bin/jq -r --arg external "$external" '
      .[] | select(.name == $external) |
      ((.availableModes // [])
        | map(
            select(test("^[0-9]+x[0-9]+@[0-9.]+Hz$"))
            | capture("^(?<width>[0-9]+)x(?<height>[0-9]+)@(?<refresh>[0-9.]+)Hz$")
            | .width as $width
            | .height as $height
            | .refresh as $refresh
            | {
                mode: "\($width)x\($height)@\($refresh)",
                pixels: (($width | tonumber) * ($height | tonumber)),
                refresh: ($refresh | tonumber)
              }
          )
        | sort_by(.pixels, .refresh)
        | last.mode) // "preferred"' | head -1)
    if [ -z "$external_mode" ]; then
      external_mode=preferred
    fi

    is_positive_integer() {
      case "$1" in
        ""|*[!0-9]*) return 1 ;;
        *) [ "$1" -gt 0 ] ;;
      esac
    }

    write_lua() {
      printf '%s\n' "-- Generated by hyprmon-profile ($profile)" > "$monitors_lua"
      printf '%s\n' "$1" >> "$monitors_lua"
      if [ -n "''${2:-}" ]; then
        printf '%s\n' "$2" >> "$monitors_lua"
      fi
    }

    case "$profile" in
      internal)
        if [ -z "$internal" ]; then
          ${pkgs.libnotify}/bin/notify-send "Display" "No internal monitor found" 2>/dev/null || true
          exit 1
        fi
        if [ -n "$external" ]; then
          write_lua \
            "hl.monitor({ output = \"$external\", disabled = true })" \
            "hl.monitor({ output = \"$internal\", mode = \"preferred\", position = \"0x0\", scale = 1.00 })"
        else
          write_lua \
            "hl.monitor({ output = \"$internal\", mode = \"preferred\", position = \"0x0\", scale = 1.00 })"
        fi
        ;;
      external)
        if [ -z "$external" ]; then
          ${pkgs.libnotify}/bin/notify-send "Display" "No external monitor found" 2>/dev/null || true
          exit 1
        fi
        if [ -n "$internal" ]; then
          if ! is_positive_integer "$internal_width"; then
            ${pkgs.libnotify}/bin/notify-send "Display" "Could not determine internal monitor width" 2>/dev/null || true
            exit 1
          fi
          write_lua \
            "hl.monitor({ output = \"$internal\", mode = \"preferred\", position = \"0x0\", scale = 1.00 })" \
            "hl.monitor({ output = \"$external\", mode = \"''${external_mode}\", position = \"''${internal_width}x0\", scale = 1.00 })"
          ${pkgs.hyprland}/bin/hyprctl reload
          ${pkgs.coreutils}/bin/sleep 0.2
          write_lua \
            "hl.monitor({ output = \"$internal\", disabled = true })" \
            "hl.monitor({ output = \"$external\", mode = \"''${external_mode}\", position = \"''${internal_width}x0\", scale = 1.00 })"
        else
          write_lua \
            "hl.monitor({ output = \"$external\", mode = \"''${external_mode}\", position = \"0x0\", scale = 1.00 })"
        fi
        ;;
      extend)
        if [ -z "$internal" ] || [ -z "$external" ]; then
          ${pkgs.libnotify}/bin/notify-send "Display" "Need both internal and external monitors" 2>/dev/null || true
          exit 1
        fi
        if ! is_positive_integer "$internal_width"; then
          ${pkgs.libnotify}/bin/notify-send "Display" "Could not determine internal monitor width" 2>/dev/null || true
          exit 1
        fi
        write_lua \
          "hl.monitor({ output = \"$internal\", mode = \"preferred\", position = \"0x0\", scale = 1.00 })" \
          "hl.monitor({ output = \"$external\", mode = \"''${external_mode}\", position = \"''${internal_width}x0\", scale = 1.00 })"
        ;;
      extend-reverse)
        if [ -z "$internal" ] || [ -z "$external" ]; then
          ${pkgs.libnotify}/bin/notify-send "Display" "Need both internal and external monitors" 2>/dev/null || true
          exit 1
        fi
        if ! is_positive_integer "$external_width"; then
          ${pkgs.libnotify}/bin/notify-send "Display" "Could not determine external monitor width" 2>/dev/null || true
          exit 1
        fi
        write_lua \
          "hl.monitor({ output = \"$internal\", disabled = true })" \
          "hl.monitor({ output = \"$external\", mode = \"''${external_mode}\", position = \"0x0\", scale = 1.00 })"
        ${pkgs.hyprland}/bin/hyprctl reload
        ${pkgs.coreutils}/bin/sleep 0.2
        write_lua \
          "hl.monitor({ output = \"$external\", mode = \"''${external_mode}\", position = \"0x0\", scale = 1.00 })" \
          "hl.monitor({ output = \"$internal\", mode = \"preferred\", position = \"''${external_width}x0\", scale = 1.00 })"
        ;;
    esac

    ${pkgs.hyprland}/bin/hyprctl reload

  '';

  caelestiaSyncGtkSettings = pkgs.writeShellScriptBin "caelestia-sync-gtk-settings" ''
        set -euo pipefail
        schemeFile="${home}/.local/state/caelestia/scheme.json"
        if [ -z "''${SCHEME_MODE:-}" ] && [ ! -f "$schemeFile" ]; then
          exit 0
        fi

        mode="''${SCHEME_MODE:-$(${pkgs.jq}/bin/jq -r .mode "$schemeFile")}"
        if [ "$mode" = "dark" ]; then
          preferDark=true
          gtkTheme=adw-gtk3-dark
          iconTheme=Papirus-Dark
          kdeColorScheme=Caelestia
          kdeLookAndFeel=org.kde.breezedark.desktop
          fallbackKdeColorScheme=BreezeDark
        else
          preferDark=false
          gtkTheme=adw-gtk3
          iconTheme=Papirus-Light
          kdeColorScheme=Caelestia
          kdeLookAndFeel=org.kde.breeze.desktop
          fallbackKdeColorScheme=BreezeLight
        fi
        kdeSchemeFile="${home}/.config/qtengine/caelestia.colors"
        fallbackKdeSchemeFile="${pkgs.kdePackages.breeze}/share/color-schemes/$fallbackKdeColorScheme.colors"
        coloursJson="''${SCHEME_COLOURS:-}"
        if [ -z "$coloursJson" ] && [ -f "$schemeFile" ]; then
          coloursJson=$(${pkgs.jq}/bin/jq -c .colours "$schemeFile")
        fi

        colour() {
          key="$1"
          fallback="$2"
          value=""
          if [ -n "$coloursJson" ]; then
            value=$(printf '%s' "$coloursJson" | ${pkgs.jq}/bin/jq -r --arg key "$key" '.[$key] // empty')
          fi

          if [ -z "$value" ] || [ "$value" = "null" ]; then
            value="$fallback"
          fi

          case "$value" in
            \#*) printf '%s\n' "$value" ;;
            *) printf '#%s\n' "$value" ;;
          esac
        }

        for ver in gtk-3.0 gtk-4.0; do
          dir="${home}/.config/$ver"
          mkdir -p "$dir"
          cat > "$dir/settings.ini" <<EOF
    [Settings]
    gtk-application-prefer-dark-theme=$preferDark
    gtk-theme-name=$gtkTheme
    gtk-icon-theme-name=$iconTheme
    EOF
        done

        export PATH="${lib.makeBinPath [ pkgs.dconf ]}:$PATH"
        dconf write /org/gnome/desktop/interface/gtk-theme "'$gtkTheme'" >/dev/null 2>&1 || true
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'" >/dev/null 2>&1 || true
        dconf write /org/gnome/desktop/interface/icon-theme "'$iconTheme'" >/dev/null 2>&1 || true

        kdeglobals="${home}/.config/kdeglobals"
        kdeUserSchemes="${home}/.local/share/color-schemes"
        mkdir -p "$kdeUserSchemes"
        if [ -f "$kdeSchemeFile" ]; then
          cp "$kdeSchemeFile" "$kdeUserSchemes/Caelestia.colors"
        else
          kdeSchemeFile="$fallbackKdeSchemeFile"
          kdeColorScheme="$fallbackKdeColorScheme"
        fi

        if [ -f "$kdeSchemeFile" ]; then
          mkdir -p "$(dirname "$kdeglobals")"
          touch "$kdeglobals"
          paletteTmp="$(mktemp)"
          kdeglobalsTmp="$(mktemp)"
          ${pkgs.gawk}/bin/awk '
            /^\[/ {
              keep = ($0 ~ /^\[(ColorEffects:|Colors:|WM\])/)
            }
            keep { print }
          ' "$kdeSchemeFile" > "$paletteTmp"
          ${pkgs.gawk}/bin/awk '
            /^\[/ {
              skip = ($0 ~ /^\[(ColorEffects:|Colors:|WM\])/)
            }
            !skip { print }
          ' "$kdeglobals" > "$kdeglobalsTmp"
          printf "\n" >> "$kdeglobalsTmp"
          cat "$paletteTmp" >> "$kdeglobalsTmp"
          mv "$kdeglobalsTmp" "$kdeglobals"
          rm -f "$paletteTmp"
        fi

        kwriteconfig6="${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"}"
        "$kwriteconfig6" --file kdeglobals --group General --key ColorScheme "$kdeColorScheme" >/dev/null 2>&1 || true
        "$kwriteconfig6" --file kdeglobals --group General --key ColorSchemeHash --delete >/dev/null 2>&1 || true
        "$kwriteconfig6" --file kdeglobals --group General --key TerminalApplication foot >/dev/null 2>&1 || true
        "$kwriteconfig6" --file kdeglobals --group General --key TerminalService foot.desktop >/dev/null 2>&1 || true
        "$kwriteconfig6" --file kdeglobals --group KDE --key LookAndFeelPackage "$kdeLookAndFeel" >/dev/null 2>&1 || true
        "$kwriteconfig6" --file kdeglobals --group KDE --key widgetStyle Breeze >/dev/null 2>&1 || true
        "$kwriteconfig6" --file kdeglobals --group Icons --key Theme "$iconTheme" >/dev/null 2>&1 || true

    starshipConfig="${home}/.config/starship.toml"
        if [ -f "$starshipConfig" ]; then
      starshipBg="$(colour surfaceContainer "$(colour surface 2b2930)")"
      starshipUser="$(colour primary 5c87cf)"
      starshipPath="$(colour kpositive "$(colour positive 36b2ff)")"
      starshipGit="$(colour knegative "$(colour negative 7f75ff)")"
      starshipNix="$(colour kneutral "$(colour neutral c794ff)")"
          starshipTime="$(colour secondaryContainer 343b4d)"
          starshipExit="$(colour primary b7c6ee)"
          starshipText="$(colour onSurface "$(colour text f2edf4)")"
          starshipAccentText="$(colour onPrimary "$starshipText")"
          starshipMuted="$(colour onSurfaceVariant "$(colour subtext1 aaa3ad)")"

      starshipTmp="$(mktemp)"
      ${pkgs.gawk}/bin/awk '
        /^\[palettes\.caelestia\]$/ {
              skip = 1
              next
            }
            /^\[/ {
              skip = 0
        }
        !skip { print }
      ' "$starshipConfig" > "$starshipTmp"
      {
        printf '\n[palettes.caelestia]\n'
        printf 'bg = "%s"\n' "$starshipBg"
        printf 'user = "%s"\n' "$starshipUser"
        printf 'path = "%s"\n' "$starshipPath"
        printf 'git = "%s"\n' "$starshipGit"
        printf 'nix = "%s"\n' "$starshipNix"
            printf 'time = "%s"\n' "$starshipTime"
            printf 'exit = "%s"\n' "$starshipExit"
            printf 'text = "%s"\n' "$starshipText"
            printf 'accent_text = "%s"\n' "$starshipAccentText"
            printf 'muted = "%s"\n' "$starshipMuted"
          } >> "$starshipTmp"
          mv "$starshipTmp" "$starshipConfig"
        fi

        fastfetchConfig="${home}/.config/fastfetch/config.jsonc"
        if [ -f "$fastfetchConfig" ]; then
          fastfetchLogoA="$(colour term1 "$(colour primary d69bb3)")"
          fastfetchLogoB="$(colour term2 "$(colour tertiary a99ad7)")"
          fastfetchDisplay="$(colour term1 "$(colour primary "$(colour text cbbbe8)")")"
          fastfetchTmp="$(mktemp)"
          ${pkgs.jq}/bin/jq \
            --arg logoA "$fastfetchLogoA" \
            --arg logoB "$fastfetchLogoB" \
            --arg display "$fastfetchDisplay" \
            '
              .logo.color."1" = $logoA
              | .logo.color."2" = $logoB
              | .logo.color."3" = $logoA
              | .logo.color."4" = $logoB
              | .logo.color."5" = $logoA
              | .logo.color."6" = $logoB
              | .display.color = $display
            ' "$fastfetchConfig" > "$fastfetchTmp" \
            && mv "$fastfetchTmp" "$fastfetchConfig" \
            || rm -f "$fastfetchTmp"
        fi

        if [ "''${CAELESTIA_SYNC_NOTIFY:-1}" != "0" ]; then
          # Tell running KDE/Qt apps to reload the palette/style/icon settings.
          for changeType in 0 2 4; do
            ${pkgs.dbus}/bin/dbus-send --session --type=signal /KGlobalSettings \
              org.kde.KGlobalSettings.notifyChange int32:"$changeType" int32:0 >/dev/null 2>&1 || true
          done
        fi
  '';

  patchedEnv =
    lib.replaceStrings
      [ ''hl.env("QT_QPA_PLATFORMTHEME", "qtengine")'' ]
      [ ''hl.env("QT_QPA_PLATFORMTHEME", "kde")'' ]
      (lib.readFile "${dots}/hypr/hyprland/env.lua");
in
{
  home.packages =
    with pkgs;
    [
      caelestiaSyncGtkSettings
      hyprmonProfile
      adw-gtk3
      darkly
      bat
      btop
      cliphist
      eza
      fastfetch
      fish
      foot
      fuzzel
      glib
      gnome-keyring
      jq
      lazygit
      micro
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nwg-displays
      papirus-icon-theme
      pavucontrol
      qtengine
      kdePackages.plasma-integration
      playerctl
      polkit_gnome
      ripgrep
      swappy
      trash-cli
      wl-clipboard
      xdg-user-dirs
      thunar
      ydotool
      zoxide
    ]
    ++ lib.optional (
      pkgs ? nerd-fonts && pkgs.nerd-fonts ? jetbrains-mono
    ) pkgs.nerd-fonts.jetbrains-mono;

  xdg.configFile = hyprlandModuleConfig // {
    "hypr/hyprland/env.lua".text = patchedEnv;
    "hypr/hyprland/execs.lua".text = patchedExecs;
    "hypr/scheme" = cfgDir "${dots}/hypr/scheme";
    "hypr/variables.lua" = cfg "${dots}/hypr/variables.lua";

    "fish/config.fish".text =
      (builtins.replaceStrings [ "zoxide init fish --cmd cd" ] [ "zoxide init fish --cmd z" ] (
        builtins.readFile "${dots}/fish/config.fish"
      ))
      + ''

        if status is-interactive
            set -gx FZF_CTRL_T_OPTS "--walker-skip .git,node_modules,target --preview='bat -n --color=always --line-range :200 {}' --preview-window=right:60%:wrap --bind='ctrl-/:toggle-preview'"
            set -gx FZF_EXPANSION_OPTS "--preview='bat -n --color=always --line-range :200 {}' --preview-window=right:60%:wrap --bind='ctrl-/:toggle-preview'"
            command -q fzf; and fzf --fish | source
        end
      '';
    "fish/functions/fish_greeting.fish".text = ''
      function fish_greeting
          command -v fastfetch &> /dev/null && fastfetch
      end
    '';
    "foot" = cfgDir "${dots}/foot";
    "fastfetch/config.base.jsonc".text = fastfetchConfig;
    "btop" = cfgDir "${dots}/btop";
    "micro" = cfgDir "${dots}/micro";
    "Thunar" = cfgDir "${dots}/thunar";
    "starship.base.toml" = cfg ../starship.toml;

    "Code/User/settings.json" = cfg vscodeSettings;
    "Code/User/keybindings.json" = cfg "${dots}/vscode/keybindings.json";
    "Cursor/User/settings.json" = cfg vscodeSettings;
    "code-flags.conf" = cfg "${dots}/vscode/flags.conf";

    "caelestia/hypr-vars.lua".text = ''
      return {
        terminal = "foot",
        browser = "zen",
        editor = "code",
        fileExplorer = "dolphin",
        kbPinWindow = "SUPER + SHIFT + P",
      }
    '';
    "caelestia/hypr-user.lua".text = ''
      local home = os.getenv("HOME")
      package.path = package.path .. ";" .. home .. "/.config/hypr/?.lua"

      if io.open(home .. "/.config/hypr/monitors.lua") then
        require("monitors")
      elseif io.open(home .. "/.config/hypr/hyprmon.lua") then
        require("hyprmon")
      end

      if io.open(home .. "/.config/hypr/workspaces.lua") then
        require("workspaces")
      end

      hl.bind("SUPER + P", hl.dsp.exec_cmd("nwg-displays"))
      hl.bind("SUPER + SHIFT + 1", hl.dsp.exec_cmd("hyprmon-profile internal"))
      hl.bind("SUPER + SHIFT + 2", hl.dsp.exec_cmd("hyprmon-profile external"))
      hl.bind("SUPER + SHIFT + 3", hl.dsp.exec_cmd("hyprmon-profile extend"))
      hl.bind("SUPER + SHIFT + 4", hl.dsp.exec_cmd("hyprmon-profile extend-reverse"))

      hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

      -- Caelestia Shell is launched with qtengine in execs.lua; native Qt apps use KDE from env.lua.
      hl.config({
        misc = {
          vrr = 0,
        },
        render = {
          direct_scanout = 0,
        },
      })
    '';
  };

  home.sessionVariables = {
    GTK2_RC_FILES = lib.mkDefault "${home}/.gtkrc-2.0";
    TERMINAL = lib.mkDefault "foot";
    KTERMINAL = lib.mkDefault "foot";
    XCURSOR_SIZE = lib.mkDefault "24";
    HYPRCURSOR_SIZE = lib.mkDefault "24";
    QT_QPA_PLATFORMTHEME = lib.mkForce "kde";
    QT_QPA_PLATFORM = lib.mkDefault "wayland;xcb";
    GDK_BACKEND = lib.mkDefault "wayland,x11";
    XDG_MENU_PREFIX = lib.mkDefault "plasma-";
  };

  home.activation.clearOldHyprShell = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    for rel in \
      .config/hypr/hyprland.conf \
      .config/hypr/colors.conf \
      .config/hypr/configs \
      .config/hypr/scripts \
      .config/hypr/UserScripts \
      .config/hypr/UserConfigs \
      .config/hypr/hypridle.conf \
      .config/hypr/hyprlock.conf \
      .config/waybar \
      .config/rofi \
      .config/swaync \
      .config/wlogout \
      .config/matugen \
      .config/cava
    do
      target="${home}/$rel"
      if [ -e "$target" ] || [ -L "$target" ]; then
        $DRY_RUN_CMD rm -rf "$target"
      fi
    done
  '';

  home.activation.clearOldHyprmonProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for rel in \
      .config/hyprmon/profiles/internal.json \
      .config/hyprmon/profiles/external.json \
      .config/hyprmon/profiles/extend.json
    do
      target="${home}/$rel"
      if [ -L "$target" ]; then
        $DRY_RUN_CMD rm -f "$target"
      fi
    done
    $DRY_RUN_CMD rmdir "${home}/.config/hyprmon/profiles" "${home}/.config/hyprmon" 2>/dev/null || true
  '';

  home.activation.caelestiaInitialState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update >/dev/null 2>&1 || true
    mkdir -p "${home}/Pictures/Wallpapers"
  '';

  home.activation.rebuildKdeServiceCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "''${DRY_RUN:-}" ]; then
      XDG_MENU_PREFIX=plasma- ${lib.getExe' pkgs.kdePackages.kservice "kbuildsycoca6"} --noincremental >/dev/null 2>&1 || true
    fi
  '';

  home.activation.starshipWritableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    starshipConfig="${home}/.config/starship.toml"
    $DRY_RUN_CMD mkdir -p "$(dirname "$starshipConfig")"
    $DRY_RUN_CMD rm -f "$starshipConfig"
    $DRY_RUN_CMD cp ${../starship.toml} "$starshipConfig"
    $DRY_RUN_CMD chmod u+w "$starshipConfig"
  '';

  home.activation.fastfetchWritableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    fastfetchConfig="${home}/.config/fastfetch/config.jsonc"
    $DRY_RUN_CMD mkdir -p "$(dirname "$fastfetchConfig")"
    $DRY_RUN_CMD rm -f "$fastfetchConfig"
    $DRY_RUN_CMD cp ${pkgs.writeText "fastfetch-config.jsonc" fastfetchConfig} "$fastfetchConfig"
    $DRY_RUN_CMD chmod u+w "$fastfetchConfig"
  '';

  # Undo stale Caelestia/Darkly KDE state, then re-apply the current dark/light mode.
  home.activation.repairKdeglobals =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "fastfetchWritableConfig"
        "starshipWritableConfig"
      ]
      ''
        kdeglobals="${home}/.config/kdeglobals"
        kwriteconfig6="${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"}"
        if [ -f "$kdeglobals" ]; then
          $kwriteconfig6 --file kdeglobals --group General --key ColorSchemeHash --delete 2>/dev/null || true
          $DRY_RUN_CMD sed -i '/^widgetStyle\[\$d\]$/d' "$kdeglobals" 2>/dev/null || true
          $DRY_RUN_CMD rm -f "${home}/.local/share/color-schemes/Caelestia.colors"
        fi
        $DRY_RUN_CMD env CAELESTIA_SYNC_NOTIFY=0 ${caelestiaSyncGtkSettings}/bin/caelestia-sync-gtk-settings
      '';

  programs.caelestia.cli.settings.theme.postHook =
    lib.mkForce "${caelestiaSyncGtkSettings}/bin/caelestia-sync-gtk-settings";

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";
    settings = { };
    extraConfig = lib.readFile "${dots}/hypr/hyprland.lua";
  };
}
