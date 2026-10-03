{
  lib,
  buildNpmPackage,
}:

buildNpmPackage rec {
  pname = "grok";
  version = "1.0.46";

  src = ./.;

  npmDepsHash = "sha256-cJgONrcPwjg8AIaQfi9e4Hic0J0IAkLaFIqpZRoNdfU=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/grok" "$out/bin"
    cp -r node_modules package.json package-lock.json "$out/lib/grok/"

    ln -s "$out/lib/grok/node_modules/@xai-official/grok/bin/grok" "$out/bin/grok"

    runHook postInstall
  '';

  meta = {
    description = "Official xAI Grok Build CLI";
    homepage = "https://x.ai/cli";
    license = lib.licenses.unfree;
    mainProgram = "grok";
    platforms = lib.platforms.linux;
  };
}
