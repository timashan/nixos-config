{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.gpu-screen-recorder.ui;
  package = cfg.package.override {
    inherit (config.security) wrapperDir;
    gpu-screen-recorder-notification = cfg.notificationPackage;
  };
in
{
  options.programs.gpu-screen-recorder.ui = {
    enable = lib.mkEnableOption "GPU Screen Recorder overlay UI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../packages/gpu-screen-recorder-ui {
        gpu-screen-recorder = config.programs.gpu-screen-recorder.package;
        gpu-screen-recorder-notification = cfg.notificationPackage;
      };
      defaultText = lib.literalExpression "pkgs.callPackage ../../packages/gpu-screen-recorder-ui { }";
      description = "The GPU Screen Recorder overlay UI package to install.";
    };

    notificationPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../packages/gpu-screen-recorder-notification { };
      defaultText = lib.literalExpression "pkgs.callPackage ../../packages/gpu-screen-recorder-notification { }";
      description = "The notification helper package used by GPU Screen Recorder UI.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      package
      cfg.notificationPackage
    ];

    security.wrappers."gsr-global-hotkeys" = {
      owner = "root";
      group = "root";
      capabilities = "cap_setuid+ep";
      source = lib.getExe' package "gsr-global-hotkeys";
    };
  };
}
