{
  lib,
  bun,
  buildNpmPackage,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "oh-my-pi";
  version = "17.3.7";

  src = ./.;
  npmDepsHash = "sha256-0PV2lCMb3v/6gfRZsjEibrGLVZDV25yjeenhrH9p93g=";

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
