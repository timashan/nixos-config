{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  qt6,
  pkgsi686Linux,
  bash,
  coreutils,
  curl,
  gawk,
  gnugrep,
  gnused,
  gnutar,
  gzip,
  gamescope,
  pciutils,
  util-linux,
  wineWow64Packages,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dlss5vklayer";
  version = "0.3.1-1";

  src = fetchurl {
    url = "https://github.com/bmitch87/DLSS5VKLayer/releases/download/${finalAttrs.version}/dlssnr-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-5n2U7nQfX3geemlh9XQ5DFUNfsTs7qdPwlCKXF2YrKc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    qt6.qtbase
    pkgsi686Linux.glibc
  ];
  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r root/usr/. "$out/"
    install -m755 ${./dlssnr-run} "$out/bin/dlssnr-run"
    install -m755 ${./dlssnr-upscale} "$out/bin/dlssnr-upscale"
    install -Dm644 ${./gamescope-mouse-sync.lua} \
      "$out/share/dlssnr/gamescope-scripts/mouse-sync.lua"
    substituteInPlace "$out/bin/dlssnr-upscale" \
      --replace-fail '@gamescopeScripts@' '${gamescope}/share/gamescope/scripts' \
      --replace-fail '@dlssnrScripts@' "$out/share/dlssnr/gamescope-scripts"
    substituteInPlace "$out/bin/dlssnr-helper" \
      --replace-fail 'RUNTIME_DIR="/tmp/dlssnr-''${DLSSNR_UID:-$UID}"' \
        'RUNTIME_DIR="$XDG_DATA_HOME/dlssnr/runtime"' \
      --replace-fail '[ -n "$shm" ] || shm="$SHM_FILE"' \
        'shm="''${DLSSNR_SHM:-''${shm:-$SHM_FILE}}"'
    for manifest in "$out"/share/vulkan/implicit_layer.d/*.json; do
      substituteInPlace "$manifest" --replace-fail /usr/lib64/dlssnr "$out/lib64/dlssnr"
    done
    ln -sfn ../lib64/dlssnr/bin/runner_probe "$out/bin/dlssnr-runner-probe"
    ln -sfn ../lib64/dlssnr/bin/dlssnr-shmctl "$out/bin/dlssnr-shmctl"
    substituteInPlace "$out/share/applications/dlssnr.desktop" \
      --replace-fail 'Exec=dlssnr-gui' "Exec=$out/bin/dlssnr-gui"
    runHook postInstall
  '';

  preFixup = ''
    wrapProgram "$out/bin/dlssnr-helper" \
      --set DLSSNR_INSTALL_DIR "$out/lib64/dlssnr" \
      --set-default __NV_PRIME_RENDER_OFFLOAD 1 \
      --set-default __GLX_VENDOR_LIBRARY_NAME nvidia \
      --set-default __VK_LAYER_NV_optimus NVIDIA_only \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
          curl
          gawk
          gnugrep
          gnused
          gnutar
          gzip
          pciutils
          util-linux
          wineWow64Packages.stable
        ]
      }
    wrapProgram "$out/bin/dlssnr-run" --prefix PATH : ${lib.makeBinPath [ coreutils ]}
    wrapProgram "$out/bin/dlssnr-upscale" \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ gamescope ]}"
    wrapProgramShell "$out/bin/dlssnr-gui" "''${qtWrapperArgs[@]}" \
      --prefix PATH : "$out/bin" \
      --run 'export DLSSNR_SHM="''${DLSSNR_SHM:-''${XDG_DATA_HOME:-$HOME/.local/share}/dlssnr/runtime/shm.bin}"'
  '';

  meta = {
    description = "Experimental DLSS 5 Vulkan layer and Wine neural-rendering helper";
    homepage = "https://github.com/bmitch87/DLSS5VKLayer";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "dlssnr-gui";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
