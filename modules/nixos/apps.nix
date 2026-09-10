{
  lib,
  pkgs,
  username,
  ...
}:

let
  zennotes = pkgs.callPackage ../../packages/zennotes { };
  gods-eye-view = pkgs.callPackage ../../packages/gods-eye-view { };

  # Resolve ships Qt5 with xcb only. Hyprland/Caelestia launch apps with
  # QT_QPA_PLATFORM=wayland, which aborts in QGuiApplication. Force XWayland
  # and the NVIDIA dGPU (PRIME offload).
  davinci-resolve = pkgs.symlinkJoin {
    name = "davinci-resolve-xcb-nvidia";
    paths = [ pkgs.davinci-resolve ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in davinci-resolve davinci-control-panels-setup davinci-fairlight-studio-utility blackmagicraw-player blackmagicraw-speedtest; do
        wrapProgram "$out/bin/$bin" \
          --set QT_QPA_PLATFORM xcb \
          --set QT_XCB_GL_INTEGRATION glx \
          --unset QT_QPA_PLATFORMTHEME \
          --unset WAYLAND_DISPLAY \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only
      done
    '';
  };
in
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
    "d /home/${username}/Documents/Vaults 0750 ${username} users -"
  ];

  environment.systemPackages =
    (with pkgs; [
      chromium
      qbittorrent
      vlc
      mpv
      handbrake
      avidemux
      ffmpeg-full
      libva-utils
      yt-dlp
      obs-studio
      kooha
      moonlight-qt
      localsend
      karere
      tor-browser
      veracrypt
      gimp
      inkscape
      blender
      godot
      audacity
      discord
      vesktop
      signal-desktop
      telegram-desktop
      bitwarden-desktop
      obsidian
      zennotes
      gods-eye-view
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
    ++ [ davinci-resolve ]
    ++ lib.optional (pkgs ? libreoffice-qt6-fresh) pkgs.libreoffice-qt6-fresh;
}
