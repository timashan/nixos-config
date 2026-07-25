{
  stdenv,
  lib,
  fetchgit,
  pkg-config,
  meson,
  ninja,
  libx11,
  libxrender,
  libxrandr,
  libxext,
  libxkbcommon,
  libglvnd,
  wayland,
  wayland-scanner,
  pango,
}:

stdenv.mkDerivation {
  pname = "gpu-screen-recorder-notification";
  version = "1.3.4";

  src = fetchgit {
    url = "https://repo.dec05eba.com/gpu-screen-recorder-notification";
    rev = "8db381865f5d03212f51fdadcf0d357ed6ea4a60";
    hash = "sha256-rGredPrTda6/3pG4+0k6fHr4fRSVCRvTC/+sRFytrWo=";
    fetchSubmodules = true;
  };

  postPatch = ''
    substituteInPlace depends/mglpp/depends/mgl/src/gl.c \
      --replace-fail "libGL.so.1" "${lib.getLib libglvnd}/lib/libGL.so.1" \
      --replace-fail "libGLX.so.0" "${lib.getLib libglvnd}/lib/libGLX.so.0" \
      --replace-fail "libEGL.so.1" "${lib.getLib libglvnd}/lib/libEGL.so.1"
  '';

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
  ];

  buildInputs = [
    libx11
    libxrender
    libxrandr
    libxext
    libxkbcommon
    libglvnd
    wayland
    wayland-scanner
    pango
  ];

  mesonBuildType = "release";

  meta = {
    description = "Notification helper for GPU Screen Recorder";
    homepage = "https://git.dec05eba.com/gpu-screen-recorder-notification/about/";
    license = lib.licenses.gpl3Only;
    mainProgram = "gsr-notify";
    platforms = [ "x86_64-linux" ];
  };
}
