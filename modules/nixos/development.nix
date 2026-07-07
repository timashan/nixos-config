{
  lib,
  pkgs,
  username,
  codexCli,
  claude-desktop,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  cursorCli = pkgs.symlinkJoin {
    name = "cursor-cli-with-agent-alias";
    paths = [ pkgs.cursor-cli ];
    postBuild = ''
      ln -s "$out/bin/cursor-agent" "$out/bin/agent"
    '';
  };
  claudeDesktop = claude-desktop.packages.${system}.claude-desktop-fhs;
in
{
  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  #   programs.adb.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Helps AppImages and upstream Linux binaries find a dynamic linker. Prefer
  # native Nix packages or dev shells when possible.
  programs.nix-ld.enable = true;

  environment.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk21.home}";
    ANDROID_HOME = "/home/${username}/Android/Sdk";
    ANDROID_SDK_ROOT = "/home/${username}/Android/Sdk";
    BROWSER = "zen-beta";
  };

  environment.systemPackages =
    (with pkgs; [
      git
      git-lfs
      gh
      nodejs_24
      pnpm
      bun
      deno
      python3
      uv
      go
      rustup
      R
      awscli2
      terraform
      opentofu
      kubectl
      kubernetes-helm
      k9s
      kind
      oci-cli
      ruff
      pyright
      gcc
      gnumake
      cmake
      pkg-config
      openssl
      docker-compose
      flutter
      android-tools
      jdk21
      devenv
      devbox
      direnv
      nix-direnv
      xdg-utils
    ])
    ++ lib.optional (pkgs ? vscode) pkgs.vscode
    ++ lib.optional (pkgs ? code-cursor) pkgs.code-cursor
    ++ lib.optional (pkgs ? cursor-cli) cursorCli
    ++ lib.optional (pkgs ? gemini-cli) pkgs.gemini-cli
    ++ lib.optional (pkgs ? android-studio) pkgs.android-studio
    ++ [ claudeDesktop ]
    ++ [ codexCli ];
}
