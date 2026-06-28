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

  patchedExecs = lib.concatStringsSep "\n" (
    lib.filter (
      line:
      !(lib.hasInfix "gammastep" line)
      && !(lib.hasInfix "geoclue-2.0/demos/agent" line)
      && !(lib.hasInfix "Location provider and night light" line)
    ) (
      lib.splitString "\n" (
        lib.replaceStrings
          [ "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ]
          [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]
          (lib.readFile "${dots}/hypr/hyprland/execs.lua")
      )
    )
  );

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
    lib.filter (name: name != "execs.lua") (builtins.attrNames (builtins.readDir "${dots}/hypr/hyprland"));

  hyprlandModuleConfig = lib.listToAttrs (
    map (name: {
      name = "hypr/hyprland/${name}";
      value = cfg "${dots}/hypr/hyprland/${name}";
    }) hyprlandModuleFiles
  );
in
{
  home.packages =
    with pkgs;
    [
      adw-gtk3
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
      '';
    };

  home.sessionVariables = {
    GTK2_RC_FILES = lib.mkDefault "${home}/.gtkrc-2.0";
    TERMINAL = lib.mkDefault "foot";
    XCURSOR_SIZE = lib.mkDefault "24";
    HYPRCURSOR_SIZE = lib.mkDefault "24";
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

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";
    settings = { };
    extraConfig = lib.readFile "${dots}/hypr/hyprland.lua";
  };
}
