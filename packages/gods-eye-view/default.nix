{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs_24,
  makeWrapper,
  xdg-utils,
}:

buildNpmPackage rec {
  pname = "gods-eye-view";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "bilawalsidhu";
    repo = "gods-eye-view";
    rev = "v${version}";
    hash = "sha256-hWUnqIPJcNG74biHCjMpih+izr5hVF91R9S4GAV6dUU=";
  };

  npmDepsHash = "sha256-j9rqTTSSsBsCrlLUeJPo8zSa0nvkvdddBprKcxmu6c0=";

  nodejs = nodejs_24;

  # puppeteer is only used for tests; skip its Chrome download in the sandbox.
  env.PUPPETEER_SKIP_DOWNLOAD = "1";

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/gods-eye-view/scripts" "$out/bin" "$out/share/applications"
    cp -r . "$out/lib/gods-eye-view/"
    install -Dm644 ${./nix-launch.mjs} "$out/lib/gods-eye-view/scripts/nix-launch.mjs"
    install -Dm644 public/logo.svg \
      "$out/share/icons/hicolor/scalable/apps/gods-eye-view.svg"

    makeWrapper ${nodejs_24}/bin/node "$out/bin/gods-eye-view" \
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs_24
          xdg-utils
        ]
      } \
      --set GEV_NIX_VERSION ${version} \
      --add-flags "$out/lib/gods-eye-view/scripts/nix-launch.mjs"

    cat > "$out/share/applications/gods-eye-view.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=God's Eye View
Comment=Live open-source spatial intelligence on a photorealistic 3D globe
Exec=$out/bin/gods-eye-view
Icon=gods-eye-view
Terminal=false
Categories=Education;Geography;Viewer;
StartupNotify=true
EOF

    runHook postInstall
  '';

  meta = {
    description = "Spy-satellite-style spatial intelligence console on a photorealistic 3D globe";
    homepage = "https://github.com/bilawalsidhu/gods-eye-view";
    license = lib.licenses.mit;
    mainProgram = "gods-eye-view";
    platforms = lib.platforms.linux;
  };
}
