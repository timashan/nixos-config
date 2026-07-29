{
  lib,
  pkgs,
  username,
  ...
}:

let
  cursorCli = pkgs.symlinkJoin {
    name = "cursor-cli-with-agent-alias";
    paths = [ pkgs.cursor-cli ];
    postBuild = ''
      ln -s "$out/bin/cursor-agent" "$out/bin/agent"
    '';
  };
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "36.1" ];
    buildToolsVersions = [ "36.1.0" ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "x86_64" ];
    includeSources = true;
    includeNDK = true;
    extraLicenses = [
      "android-sdk-preview-license"
    ];
  };
  androidSdk = androidComposition.androidsdk;
  androidAvdHome = "/home/${username}/.config/.android/avd";
  androidSdkTools = pkgs.symlinkJoin {
    name = "android-sdk-tools-with-nixos-paths";
    paths = [ androidSdk ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for tool in emulator avdmanager sdkmanager adb; do
        if [ -x "$out/bin/$tool" ]; then
          wrapProgram "$out/bin/$tool" \
            --set ANDROID_HOME "${androidSdk}/libexec/android-sdk" \
            --set ANDROID_SDK_ROOT "${androidSdk}/libexec/android-sdk" \
            --set ANDROID_NDK_ROOT "${androidSdk}/libexec/android-sdk/ndk-bundle" \
            --set ANDROID_AVD_HOME "${androidAvdHome}"
        fi
      done
    '';
  };
  androidStudio = pkgs.symlinkJoin {
    name = "android-studio-with-nixos-sdk";
    paths = [ (pkgs.android-studio.withSdk androidSdk) ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/android-studio" \
        --set ANDROID_HOME "${androidSdk}/libexec/android-sdk" \
        --set ANDROID_SDK_ROOT "${androidSdk}/libexec/android-sdk" \
        --set ANDROID_NDK_ROOT "${androidSdk}/libexec/android-sdk/ndk-bundle" \
        --set ANDROID_AVD_HOME "${androidAvdHome}"
    '';
  };
in
{
  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
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
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
    ANDROID_AVD_HOME = androidAvdHome;
    BROWSER = "zen-beta";
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
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
      androidSdkTools
      android-tools
      jdk21
      devenv
      devbox
      just
      direnv
      nix-direnv
      xdg-utils
    ])
    ++ lib.optional (pkgs ? vscode) pkgs.vscode
    ++ lib.optional (pkgs ? code-cursor) pkgs.code-cursor
    ++ lib.optional (pkgs ? cursor-cli) cursorCli
    ++ lib.optional (pkgs ? android-studio) androidStudio
    ++ lib.optional (pkgs ? gemini-cli) pkgs.gemini-cli;
}
