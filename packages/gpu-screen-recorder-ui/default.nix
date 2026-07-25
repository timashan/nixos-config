{
  stdenv,
  lib,
  pkgs,
  fetchgit,
  pkg-config,
  addDriverRunpath,
  desktop-file-utils,
  makeWrapper,
  meson,
  ninja,
  cmake,
  libpulseaudio,
  libdrm,
  mesa,
  gpu-screen-recorder,
  libglvnd,
  libX11,
  libXrandr,
  libXcomposite,
  libXcursor,
  libXext,
  libXfixes,
  libXrender,
  libXi,
  libcap,
  freetype,
  glib,
  pango,
  gpu-screen-recorder-notification,
  dbus,
  wayland,
  wayland-scanner,
  wrapGAppsHook3,
  libxkbcommon,
  gsettings-desktop-schemas,
  wrapperDir ? "/run/wrappers/bin",
}:

stdenv.mkDerivation {
  pname = "gpu-screen-recorder-ui";
  version = "1.13.2";

  src = fetchgit {
    url = "https://repo.dec05eba.com/gpu-screen-recorder-ui";
    rev = "08d4ea83921a876edc74f388b4d4b3ba7aba87d5";
    hash = "sha256-aYD+efjfGEmLmc+fxpSguwpdL82iyF3OoHFJBUe7Kms=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
    makeWrapper
    meson
    cmake
    ninja
  ];

  buildInputs = [
    gsettings-desktop-schemas
    libxkbcommon
    freetype
    glib
    pango
    libpulseaudio
    desktop-file-utils
    libdrm
    libX11
    libXrandr
    libXcomposite
    libXcursor
    libXext
    libXfixes
    libXrender
    libXi
    wayland
    dbus
    wayland-scanner
    libcap
  ];

  preFixup =
    let
      gpu-screen-recorder-wrapped = gpu-screen-recorder.override {
        inherit wrapperDir;
      };
    in
    ''
      wrapProgram "$out/bin/gsr-ui" \
        --set __NV_PRIME_RENDER_OFFLOAD 1 \
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
        --set __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set __VK_LAYER_NV_optimus NVIDIA_only \
        --prefix PATH : ${wrapperDir} \
        --suffix PATH : "${
          lib.makeBinPath [
            gpu-screen-recorder-notification
            gpu-screen-recorder-wrapped
            pkgs.bash
          ]
        }:$out/bin" \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            mesa
            libglvnd
            addDriverRunpath.driverLink
          ]
        }"
    '';

  meta = {
    description = "ShadowPlay-like frontend for GPU Screen Recorder";
    homepage = "https://git.dec05eba.com/gpu-screen-recorder-ui/about/";
    license = lib.licenses.gpl3Only;
    mainProgram = "gsr-ui";
    platforms = [ "x86_64-linux" ];
  };
}
