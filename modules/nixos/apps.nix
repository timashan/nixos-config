{
  lib,
  pkgs,
  username,
  helium-browser,
  ...
}:

let
  signal-desktop = pkgs.callPackage ../../packages/signal-desktop { };
  zennotes = pkgs.callPackage ../../packages/zennotes { };
  gods-eye-view = pkgs.callPackage ../../packages/gods-eye-view { };

  # Avidemux's preview is blank on native Wayland (nixpkgs#445657), and
  # VDPAU/LibVA overlays stay black on Hyprland XWayland with PRIME.
  # Force XCB and drop the KDE/Wayland env so Qt simpleRender can paint.
  avidemux = pkgs.symlinkJoin {
    name = "avidemux-xcb";
    paths = [ pkgs.avidemux ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in avidemux avidemux3_qt5 avidemux3_jobs_qt5; do
        wrapProgram "$out/bin/$bin" \
          --set QT_QPA_PLATFORM xcb \
          --set QT_XCB_GL_INTEGRATION glx \
          --unset QT_QPA_PLATFORMTHEME \
          --unset WAYLAND_DISPLAY
      done
    '';
  };

  seedHelium = pkgs.writeShellApplication {
    name = "seed-helium-profile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.python3
    ];
    text = ''
      export HELIUM_BOOKMARK_CONVERTER=${../../home/main/netscape-to-chromium-bookmarks.py}
      export HELIUM_EXTENSIONS_DIR=${heliumExtensions}
      python3 ${../../home/main/seed-helium-profile.py}
    '';
  };

  heliumExtensions = pkgs.callPackage ../../packages/helium-extensions { };

  wrapHelium =
    pkg:
    let
      wrapped = pkgs.symlinkJoin {
        name = "${pkg.pname or "helium"}-seeded";
        paths = [ pkg ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/helium" \
            --run ${lib.escapeShellArg (lib.getExe seedHelium)} \
            --add-flags --no-default-browser-check
          mkdir -p "$out/share/applications"
          rm -f "$out/share/applications/helium.desktop"
          cp "${pkg}/share/applications/helium.desktop" "$out/share/applications/helium.desktop"
          chmod u+w "$out/share/applications/helium.desktop"
          substituteInPlace "$out/share/applications/helium.desktop" \
            --replace-fail "${pkg}/bin/helium" "$out/bin/helium"
        '';
      };
    in
    wrapped
    // {
      inherit (pkg) pname version meta;
      override = args: wrapHelium (pkg.override args);
    };

  heliumPkg = wrapHelium helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium;

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

  programs.helium = {
    enable = true;
    package = heliumPkg;
  };

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
    ++ [
      avidemux
      davinci-resolve
    ]
    ++ lib.optional (pkgs ? libreoffice-qt6-fresh) pkgs.libreoffice-qt6-fresh;
}
