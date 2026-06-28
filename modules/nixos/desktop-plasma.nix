{ lib, pkgs, ... }:

let
  sddmKcminputrc = pkgs.writeText "sddm-kcminputrc" ''
    [Keyboard]
    NumLock=0
  '';
in
{
  # Plasma 6 is the stable default here. It gives good Wayland, monitor, audio,
  # Bluetooth, power, and NVIDIA hybrid graphics integration without needing a
  # custom compositor setup on day one.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # Wayland SDDM uses KWin, which reads /var/lib/sddm/.config/kcminputrc for Num Lock.
    # sddm.conf Numlock=on and xkb num:alwayson only fight that and cause ON→OFF→ON flicker.
    settings.General.GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/sddm/.config 0755 sddm sddm -"
    "L+ /var/lib/sddm/.config/kcminputrc - - - - ${sddmKcminputrc}"
  ];
  services.desktopManager.plasma6.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [ "gtk" ];
      Hyprland.default = [
        "hyprland"
        "gtk"
      ];
      KDE.default = [
        "kde"
        "gtk"
      ];
    };
  };

  services.libinput.enable = true;
  services.flatpak.enable = true;

  programs.dconf.enable = true;
  programs.kdeconnect.enable = true;

  fonts = {
    fontconfig.enable = true;
    packages =
      (with pkgs; [
        inter
        jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        dejavu_fonts
      ])
      ++ lib.optional (pkgs ? nerd-fonts && pkgs.nerd-fonts ? jetbrains-mono) pkgs.nerd-fonts.jetbrains-mono;
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.ark
    kdePackages.gwenview
    kdePackages.okular
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.dolphin-plugins
    pavucontrol
    crosspipe
  ];
}
