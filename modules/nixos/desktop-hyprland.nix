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
    glib
    gnome-keyring
    grim
    hyprpicker
    jq
    kitty
    libnotify
    micro
    networkmanagerapplet
    papirus-icon-theme
    pavucontrol
    qtengine
    darkly
    kdePackages.plasma-integration
    playerctl
    polkit_gnome
    slurp
    swappy
    trash-cli
    wl-clipboard
    wireplumber
    xdg-user-dirs
    thunar
    warp-terminal
    ydotool
    zoxide
  ];
}
