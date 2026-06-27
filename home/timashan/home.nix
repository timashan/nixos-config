{
  config,
  lib,
  pkgs,
  username,
  codex-desktop-linux,
  codexCli,
  zen-browser,
  ...
}:

{
  imports = [
    codex-desktop-linux.homeManagerModules.default
    zen-browser.homeModules.beta
  ];

  programs.codexDesktopLinux = {
    enable = true;
    cliPackage = codexCli;
  };

  programs.zen-browser.enable = true;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    BROWSER = lib.getExe pkgs.firefox;
    ANDROID_HOME = "/home/${username}/Android/Sdk";
    ANDROID_SDK_ROOT = "/home/${username}/Android/Sdk";
  };

  # KDE Wayland: Electron is more reliable on X11 (codex-desktop-linux docs).
  home.file.".config/codex-desktop/electron-flags.conf" = {
    force = true;
    text = ''
      # Managed by Home Manager — Codex Desktop Linux launch flags.
      # https://github.com/ilysenko/codex-desktop-linux/blob/main/docs/troubleshooting.md
      --ozone-platform=x11
    '';
  };

  home.activation.codexDesktop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codexHome="${config.home.homeDirectory}/.codex"
    configToml="$codexHome/config.toml"
    globalState="$codexHome/.codex-global-state.json"

    # Read-only plugin staging dirs from the Nix store break Codex Desktop.
    $DRY_RUN_CMD rm -rf "$codexHome/.tmp/bundled-marketplaces/"*.staging-* 2>/dev/null || true

    # Workaround for desktop onboarding / workspace-deps limbo (openai/codex#22009).
    if [ -f "$configToml" ] && ! grep -q '^apps[[:space:]]*=' "$configToml"; then
      if grep -q '^\[features\]' "$configToml"; then
        $DRY_RUN_CMD sed -i '/^\[features\]/a apps = true' "$configToml"
      else
        $DRY_RUN_CMD printf '\n[features]\napps = true\n' >> "$configToml"
      fi
    fi

    # Unstick onboarding when runtime installed but Desktop state never advanced.
    if [ -f "$globalState" ]; then
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 - <<'PY'
import json
from pathlib import Path

p = Path("${config.home.homeDirectory}/.codex/.codex-global-state.json")
data = json.loads(p.read_text())
atom = data.get("electron-persisted-atom-state", {})
runtime_ready = Path(
    "${config.home.homeDirectory}/.cache/codex-runtimes/codex-primary-runtime/runtime.json"
).is_file()
stuck = (
    atom.get("electron:onboarding-primary-runtime-install-requested") is True
    and atom.get("electron:onboarding-primary-runtime-install-ready") is False
) or atom.get("electron:onboarding-welcome-pending") is True

if runtime_ready and stuck:
    atom["electron:onboarding-primary-runtime-install-ready"] = True
    atom["electron:onboarding-primary-runtime-install-requested"] = False
    atom["electron:onboarding-welcome-pending"] = False
    data["electron-persisted-atom-state"] = atom
    p.write_text(json.dumps(data))
PY
    fi
  '';

  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -lah";
      gs = "git status";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#tuf-a15";
      test-rebuild = "sudo nixos-rebuild test --flake ~/nixos-config#tuf-a15";
      codex-login = "codex login --device-auth";
    };
    initContent = ''
      bindkey -e
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };

  home.packages = with pkgs; [
    lazygit
    jq
    yq
    eza
    bat
    fzf
    ripgrep
    fd
  ];
}
