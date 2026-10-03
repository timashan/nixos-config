{
  lib,
  bun,
  buildNpmPackage,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "oh-my-pi";
  version = "18.5.1";

  src = ./.;
  npmDepsHash = "sha256-Voq2fxFpnIJEJMEdTvV28tVW+HadC6Ml3De0KfVmRzo=";

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/oh-my-pi" "$out/bin"
    cp -r node_modules package.json package-lock.json "$out/lib/oh-my-pi/"
    makeWrapper ${bun}/bin/bun "$out/bin/omp" \
      --add-flags "$out/lib/oh-my-pi/node_modules/@oh-my-pi/pi-coding-agent/dist/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "AI coding agent for the terminal";
    homepage = "https://omp.sh";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = lib.platforms.linux;
  };
}
