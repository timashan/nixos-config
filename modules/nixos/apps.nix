{ lib, pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages =
    (with pkgs; [
      chromium
      qbittorrent
      vlc
      mpv
      ffmpeg-full
      yt-dlp
      obs-studio
      gimp
      inkscape
      discord
      vesktop
      signal-desktop
      telegram-desktop
      bitwarden-desktop
      zip
      unzip
      p7zip
      unrar
      xz
      zstd
      rar
    ])
    ++ lib.optional (pkgs ? libreoffice-qt6-fresh) pkgs.libreoffice-qt6-fresh;
}
