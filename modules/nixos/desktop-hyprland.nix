{ pkgs, ... }:

{
  # Hyprland session at SDDM alongside Plasma (primary).
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Explicit PipeWire stack — works in Hyprland even when Plasma is not running.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    blueman
    bluez
    bluez-tools
    brightnessctl
    btop
    cava
    cliphist
    ddcutil
    eza
    fastfetch
    fish
    foot
    fuzzel
    gammastep
    glib
    gnome-keyring
    grim
    hyprpicker
    jq
    libnotify
    micro
    networkmanagerapplet
    papirus-icon-theme
    pavucontrol
    playerctl
    polkit_gnome
    slurp
    swappy
    trash-cli
    wl-clipboard
    wireplumber
    xdg-user-dirs
    thunar
    ydotool
    zoxide
  ];
}
