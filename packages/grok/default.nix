{
  lib,
  buildNpmPackage,
  nodejs_24,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "grok";
  version = "1.0.13";

  src = ./.;

  npmDepsHash = "sha256-hYtyswu8PpSBX1l32LtGF6B4bSVdzIueVf589uCG2V0=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/grok" "$out/bin"
    cp -r node_modules package.json package-lock.json "$out/lib/grok/"

    makeWrapper ${nodejs_24}/bin/node "$out/bin/grok" \
      --add-flags "$out/lib/grok/node_modules/@xai-official/grok/bin/grok"

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
