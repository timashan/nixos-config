{
  lib,
  bun,
  buildNpmPackage,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "oh-my-pi";
  version = "16.4.6";

  src = ./.;
  npmDepsHash = "sha256-tHnA5wpxQ7Zze3vVXHTpF26gIjUEEcg/IaO5X0FJS54=";

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/oh-my-pi" "$out/bin"
    cp -r node_modules package.json package-lock.json "$out/lib/oh-my-pi/"
    substituteInPlace "$out/lib/oh-my-pi/node_modules/@oh-my-pi/pi-coding-agent/dist/cli.js" \
      --replace-fail 'bun:">=1.3.14"' 'bun:">=1.3.13"'

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
