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

  patchedExecs =
    lib.replaceStrings
      [
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
        "/usr/lib/geoclue-2.0/demos/agent"
      ]
      [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${pkgs.geoclue2}/libexec/geoclue-2.0/demos/agent"
      ]
      (lib.readFile "${dots}/hypr/hyprland/execs.lua");

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
      gammastep
      glib
      gnome-keyring
      jq
      lazygit
      micro
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
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

      "fish" = cfgDir "${dots}/fish";
      "foot" = cfgDir "${dots}/foot";
      "fastfetch" = cfgDir "${dots}/fastfetch";
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
        }
      '';
      "caelestia/hypr-user.lua".text = ''
        return {}
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
