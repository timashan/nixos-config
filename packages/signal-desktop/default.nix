{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "signal-desktop";
  version = "8.27.0";

  # Use Signal's official release while nixpkgs trails the current version.
  src = fetchurl {
    url = "https://updates.signal.org/desktop/signal-desktop_${version}_x86_64.AppImage";
    hash = "sha256-yUbxOcx9dFBQPGWymgnTtMyw0vhVVnjK0XMe2VytDu0=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The AppImage environment replaces /etc, so callers may be in a hidden cwd.
  chdirToPwd = false;
  extraBwrapArgs = [ "--chdir \"$HOME\"" ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/signal-desktop.desktop "$out/share/applications/signal.desktop"
    substituteInPlace "$out/share/applications/signal.desktop" \
      --replace-fail "Exec=AppRun %U" "Exec=signal-desktop %U"
    cp -r ${appimageContents}/usr/share/icons "$out/share/"
  '';

  meta = {
    description = "Private, simple, and secure messenger";
    homepage = "https://signal.org/";
    changelog = "https://github.com/signalapp/Signal-Desktop/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "signal-desktop";
    platforms = [ "x86_64-linux" ];
  };
}
