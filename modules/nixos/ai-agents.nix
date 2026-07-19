{
  lib,
  pkgs,
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
  ohMyPi = pkgs.callPackage ../../packages/oh-my-pi { };
in
{
  environment.systemPackages =
    lib.optional (pkgs ? claude-code) pkgs.claude-code
    ++ lib.optional (pkgs ? opencode) pkgs.opencode
    ++ lib.optional (pkgs ? pi-coding-agent) pkgs.pi-coding-agent
    ++ lib.optional (pkgs ? openclaw) pkgs.openclaw
    ++ [
      codexCli
      claudeDesktop
      hermesAgent
      herdrPackage
      ohMyPi
      pkgs.t3code
    ];
}
