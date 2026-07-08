{
  lib,
  pkgs,
  username,
  ...
}:

{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.thunderbird = {
    enable = true;
    preferences."mail.shell.checkDefaultClient" = false;
    policies.ExtensionSettings."google-chat-tab@eternaltyro" = {
      install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/google-chat-tab/latest.xpi";
      installation_mode = "force_installed";
    };
  };

  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";
    openDefaultPorts = true;

    # Keep devices and shared folders editable from Syncthing's web UI.
    overrideDevices = false;
    overrideFolders = false;
  };

  systemd.tmpfiles.rules = [
    "d /home/${username}/Documents 0755 ${username} users -"
    "d /home/${username}/Documents/Obsidian 0750 ${username} users -"
  ];

  environment.systemPackages =
    (with pkgs; [
      chromium
      qbittorrent
      vlc
      mpv
      ffmpeg-full
      yt-dlp
      obs-studio
      moonlight-qt
      karere
      tor-browser
      veracrypt
      gimp
      inkscape
      discord
      vesktop
      signal-desktop
      telegram-desktop
      bitwarden-desktop
      obsidian
      syncthing
      syncthingtray
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
