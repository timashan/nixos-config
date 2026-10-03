{
  lib,
  pkgs,
  aiPkgs,
  codexCli,
  claude-desktop,
  hermes-agent,
  herdr,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  claudeDesktop = claude-desktop.packages.${system}.claude-desktop-fhs;
  hermesAgent = hermes-agent.packages.${system}.default;
  herdrPackage = herdr.packages.${system}.default;
  grok = aiPkgs.callPackage ../../packages/grok { };
  ohMyPi = aiPkgs.callPackage ../../packages/oh-my-pi { };
in
{
  environment.systemPackages =
    lib.optional (aiPkgs ? claude-code) aiPkgs.claude-code
    ++ lib.optional (aiPkgs ? opencode) aiPkgs.opencode
    ++ lib.optional (aiPkgs ? pi-coding-agent) aiPkgs.pi-coding-agent
    ++ lib.optional (aiPkgs ? openclaw) aiPkgs.openclaw
    ++ [
      codexCli
      claudeDesktop
      grok
      hermesAgent
      herdrPackage
      ohMyPi
      aiPkgs.t3code
    ];
}
