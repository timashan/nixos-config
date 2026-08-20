{ pkgs, ... }:

let
  coverThumbnailer = pkgs.callPackage ../../packages/cover-thumbnailer { };
in
{
  # Folder thumbnails are useful in the file view, but make the compact
  # navigation icons hard to recognize. Keep them out of the side pane and
  # location entry while retaining them everywhere else.
  nixpkgs.overlays = [
    (_final: previous: {
      # Patch the underlying package so programs.thunar can wrap it with
      # plugins without discarding the patch.
      thunar-unwrapped = previous.thunar-unwrapped.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ../../packages/thunar/navigation-icons.patch
        ];
      });
    })
  ];

  # Thunar needs its NixOS module for D-Bus, Xfconf, and plugin registration.
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  # File previews and userspace mounting for Thunar.
  services.tumbler.enable = true;
  services.gvfs.enable = true;

  # Hyprland session at SDDM alongside Plasma (primary).
  programs.hyprland = {
    enable = true;
    withUWSM = true;
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
    file-roller
    fish
    foot
    coverThumbnailer
    fuzzel
    ffmpegthumbnailer
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
    warp-terminal
    ydotool
    zoxide
  ];
}
