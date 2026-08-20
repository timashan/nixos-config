{
  fetchFromGitHub,
  ffmpegthumbnailer,
  gettext,
  gtk3,
  lib,
  librsvg,
  poppler-utils,
  python3,
  stdenvNoCC,
  wrapGAppsHook3,
}:

let
  python = python3.withPackages (
    packages: with packages; [
      pillow
      pygobject3
    ]
  );
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cover-thumbnailer";
  version = "0.10.3";

  src = fetchFromGitHub {
    owner = "flozz";
    repo = "cover-thumbnailer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dBuUqwmClKBCwcX5+6SMOlHu3BCqb4lzpM4OUpf6oUI=";
  };

  patches = [
    ./papirus-style.patch
    ./global-media.patch
  ];

  nativeBuildInputs = [
    gettext
    librsvg
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    python
  ];

  dontBuild = true;
  dontWrapGApps = true;

  postPatch = ''
    substituteInPlace cover-thumbnailer.py cover-thumbnailer-gui.py \
      --replace-fail '/usr/share/cover-thumbnailer/' "$out/share/cover-thumbnailer/"
    substituteInPlace cover-thumbnailer.py \
      --replace-fail '@ffmpegthumbnailer@' '${lib.getExe ffmpegthumbnailer}' \
      --replace-fail '@pdftoppm@' '${lib.getExe' poppler-utils "pdftoppm"}'
    substituteInPlace freedesktop/cover-thumbnailer-gui.desktop \
      --replace-fail 'Icon=/usr/share/cover-thumbnailer/icon.png' \
        "Icon=$out/share/cover-thumbnailer/icon.png"
    substituteInPlace freedesktop/cover.thumbnailer \
      --replace-fail 'TryExec=cover-thumbnailer' "TryExec=$out/bin/cover-thumbnailer" \
      --replace-fail 'Exec=cover-thumbnailer %u %o' \
        "Exec=$out/bin/cover-thumbnailer %u %o"
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 cover-thumbnailer.py "$out/bin/cover-thumbnailer"
    install -Dm755 cover-thumbnailer-gui.py "$out/bin/cover-thumbnailer-gui"
    patchShebangs "$out/bin"

    install -Dm644 share/* -t "$out/share/cover-thumbnailer"
    rsvg-convert ${./pictures-background.svg} \
      -o "$out/share/cover-thumbnailer/pictures_bg.png"
    rsvg-convert ${./pictures-foreground.svg} \
      -o "$out/share/cover-thumbnailer/pictures_fg.png"
    install -Dm644 freedesktop/cover.thumbnailer \
      "$out/share/thumbnailers/cover.thumbnailer"
    install -Dm644 freedesktop/cover-thumbnailer-gui.desktop \
      "$out/share/applications/cover-thumbnailer-gui.desktop"
    install -Dm644 man/cover-thumbnailer.1 \
      "$out/share/man/man1/cover-thumbnailer.1"
    install -Dm644 man/cover-thumbnailer-gui.1 \
      "$out/share/man/man1/cover-thumbnailer-gui.1"

    for translation in locale/*.po; do
      language=$(basename "$translation" .po)
      mkdir -p "$out/share/locale/$language/LC_MESSAGES"
      msgfmt "$translation" \
        -o "$out/share/locale/$language/LC_MESSAGES/cover-thumbnailer-gui.mo"
    done

    runHook postInstall
  '';

  postFixup = ''
    wrapGApp "$out/bin/cover-thumbnailer"
    wrapGApp "$out/bin/cover-thumbnailer-gui"
  '';

  meta = {
    description = "Global image, video, and PDF folder previews for Thunar";
    homepage = "https://github.com/flozz/cover-thumbnailer";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    mainProgram = "cover-thumbnailer";
    platforms = lib.platforms.linux;
  };
})
