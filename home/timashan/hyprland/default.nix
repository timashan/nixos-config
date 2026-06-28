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

  patchedExecs = lib.concatStringsSep "\n" (
    lib.filter (
      line:
      !(lib.hasInfix "gammastep" line)
      && !(lib.hasInfix "geoclue-2.0/demos/agent" line)
      && !(lib.hasInfix "Location provider and night light" line)
    ) (
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
    hl.exec_cmd("${systemctl} --user set-environment QT_QPA_PLATFORMTHEME=kde 'QT_QPA_PLATFORM=wayland;xcb' GDK_BACKEND=wayland,x11")
    hl.exec_cmd("${dbusUpdate} --systemd QT_QPA_PLATFORMTHEME=kde 'QT_QPA_PLATFORM=wayland;xcb' GDK_BACKEND=wayland,x11 XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland XDG_SESSION_DESKTOP=Hyprland")

    -- Sync toolkit settings for native apps without repainting apps during startup.
    hl.exec_cmd("CAELESTIA_SYNC_NOTIFY=0 caelestia-sync-gtk-settings")
'';

  fastfetchConfig = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "builtin",
        "source": "NixOS",
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

  hyprlandModuleFiles =
    lib.filter (name: !(builtins.elem name [ "env.lua" "execs.lua" ])) (
      builtins.attrNames (builtins.readDir "${dots}/hypr/hyprland")
    );

  hyprlandModuleConfig = lib.listToAttrs (
    map (name: {
      name = "hypr/hyprland/${name}";
      value = cfg "${dots}/hypr/hyprland/${name}";
    }) hyprlandModuleFiles
  );

  caelestiaSyncGtkSettings = pkgs.writeShellScriptBin "caelestia-sync-gtk-settings" ''
    set -euo pipefail
    schemeFile="${home}/.local/state/caelestia/scheme.json"
    if [ ! -f "$schemeFile" ]; then
      exit 0
    fi

    mode=$(${pkgs.jq}/bin/jq -r .mode "$schemeFile")
    if [ "$mode" = "dark" ]; then
      preferDark=true
      gtkTheme=adw-gtk3-dark
      iconTheme=Papirus-Dark
      kdeColorScheme=BreezeDark
      kdeLookAndFeel=org.kde.breezedark.desktop
    else
      preferDark=false
      gtkTheme=adw-gtk3
      iconTheme=Papirus-Light
      kdeColorScheme=BreezeLight
      kdeLookAndFeel=org.kde.breeze.desktop
    fi

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
    kdeSchemeFile="${pkgs.kdePackages.breeze}/share/color-schemes/$kdeColorScheme.colors"
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
    "$kwriteconfig6" --file kdeglobals --group KDE --key LookAndFeelPackage "$kdeLookAndFeel" >/dev/null 2>&1 || true
    "$kwriteconfig6" --file kdeglobals --group KDE --key widgetStyle Breeze >/dev/null 2>&1 || true
    "$kwriteconfig6" --file kdeglobals --group Icons --key Theme "$iconTheme" >/dev/null 2>&1 || true

    if [ "''${CAELESTIA_SYNC_NOTIFY:-1}" != "0" ]; then
      # Tell running KDE/Qt apps to reload the palette/style/icon settings.
      for changeType in 0 2 4; do
        ${pkgs.dbus}/bin/dbus-send --session --type=signal /KGlobalSettings \
          org.kde.KGlobalSettings.notifyChange int32:"$changeType" int32:0 >/dev/null 2>&1 || true
      done
    fi
  '';

  patchedEnv = lib.replaceStrings
    [ ''hl.env("QT_QPA_PLATFORMTHEME", "qtengine")'' ]
    [ ''hl.env("QT_QPA_PLATFORMTHEME", "kde")'' ]
    (lib.readFile "${dots}/hypr/hyprland/env.lua");
in
{
  home.packages =
    with pkgs;
    [
      caelestiaSyncGtkSettings
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
    ++ lib.optional (pkgs ? nerd-fonts && pkgs.nerd-fonts ? jetbrains-mono) pkgs.nerd-fonts.jetbrains-mono;

  xdg.configFile =
    hyprlandModuleConfig
    // {
      "hypr/hyprland/env.lua".text = patchedEnv;
      "hypr/hyprland/execs.lua".text = patchedExecs;
      "hypr/scheme" = cfgDir "${dots}/hypr/scheme";
      "hypr/variables.lua" = cfg "${dots}/hypr/variables.lua";

      "fish/config.fish" = cfg "${dots}/fish/config.fish";
      "fish/functions/fish_greeting.fish".text = ''
        function fish_greeting
            command -v fastfetch &> /dev/null && fastfetch
        end
      '';
      "foot" = cfgDir "${dots}/foot";
      "fastfetch/config.jsonc".text = fastfetchConfig;
      "btop" = cfgDir "${dots}/btop";
      "micro" = cfgDir "${dots}/micro";
      "Thunar" = cfgDir "${dots}/thunar";
      "starship.toml" = cfg "${dots}/starship.toml";

      "Code/User/settings.json" = cfg "${dots}/vscode/settings.json";
      "Code/User/keybindings.json" = cfg "${dots}/vscode/keybindings.json";
      "code-flags.conf" = cfg "${dots}/vscode/flags.conf";

      "caelestia/hypr-vars.lua".text = ''
        return {
          terminal = "foot",
          browser = "zen",
          editor = "code",
          fileExplorer = "thunar",
          kbPinWindow = "SUPER + SHIFT + P",
        }
      '';
      "caelestia/hypr-user.lua".text = ''
        local home = os.getenv("HOME")
        package.path = package.path .. ";" .. home .. "/.config/hypr/?.lua"

        if io.open(home .. "/.config/hypr/monitors.lua") then
          require("monitors")
        end

        if io.open(home .. "/.config/hypr/workspaces.lua") then
          require("workspaces")
        end

        hl.bind("SUPER + P", hl.dsp.exec_cmd("nwg-displays"))

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
    XCURSOR_SIZE = lib.mkDefault "24";
    HYPRCURSOR_SIZE = lib.mkDefault "24";
    QT_QPA_PLATFORMTHEME = lib.mkForce "kde";
    QT_QPA_PLATFORM = lib.mkDefault "wayland;xcb";
    GDK_BACKEND = lib.mkDefault "wayland,x11";
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

  home.activation.caelestiaInitialState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update >/dev/null 2>&1 || true
    mkdir -p "${home}/Pictures/Wallpapers"
  '';

  # Undo stale Caelestia/Darkly KDE state, then re-apply the current dark/light mode.
  home.activation.repairKdeglobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kdeglobals="${home}/.config/kdeglobals"
    kwriteconfig6="${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"}"
    if [ -f "$kdeglobals" ]; then
      $kwriteconfig6 --file kdeglobals --group General --key ColorSchemeHash --delete 2>/dev/null || true
      $DRY_RUN_CMD sed -i '/^widgetStyle\[\$d\]$/d' "$kdeglobals" 2>/dev/null || true
      $DRY_RUN_CMD rm -f "${home}/.local/share/color-schemes/Caelestia.colors"
    fi
    $DRY_RUN_CMD env CAELESTIA_SYNC_NOTIFY=0 ${caelestiaSyncGtkSettings}/bin/caelestia-sync-gtk-settings
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";
    settings = { };
    extraConfig = lib.readFile "${dots}/hypr/hyprland.lua";
  };
}
