{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "zennotes";
  version = "2.29.0";

  src = fetchurl {
    url = "https://github.com/ZenNotes/zennotes/releases/download/v${version}/ZenNotes-${version}-linux-x86_64.AppImage";
    hash = "sha256-r8yzd+1CtXwbHvd4pPxYTiMhxbs+WYxOMyp83GM4zjE=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/resources/arch-extras/zennotes.desktop \
      "$out/share/applications/zennotes.desktop"
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/ZenNotes.png \
      "$out/share/icons/hicolor/512x512/apps/zennotes.png"

    cat > "$out/bin/zn" <<EOF
    #!/bin/sh
    ELECTRON_RUN_AS_NODE=1 exec "$out/bin/zennotes" "${appimageContents}/resources/cli.js" "\$@"
    EOF
    chmod +x "$out/bin/zn"
  '';

  meta = {
    description = "Keyboard-first, local-first Markdown notes with Vim motions and live preview";
    homepage = "https://github.com/ZenNotes/zennotes";
    license = lib.licenses.mit;
    mainProgram = "zennotes";
    platforms = [ "x86_64-linux" ];
  };
}
