{
  config,
  lib,
  pkgs,
  hostname,
  codex-desktop-linux,
  codexCli,
  zen-browser,
  caelestia-shell,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  patchedCaelestiaShell = (
    caelestia-shell.packages.${system}.caelestia-shell.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        launcher="$out/share/caelestia-shell/modules/launcher/services/Apps.qml"
        substituteInPlace "$launcher" \
          --replace-fail "            entry.execute();" "            Quickshell.execDetached({ command: [\"env\", \"QT_QPA_PLATFORMTHEME=kde\", \"QT_QPA_PLATFORM=wayland\", \"GDK_BACKEND=wayland,x11\", ...entry.command], workingDirectory: entry.workingDirectory });"
      '';
    })
  );
in
{
  imports = [
    ../../modules/home-manager/base.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
    codex-desktop-linux.homeManagerModules.default
    zen-browser.homeModules.beta
    caelestia-shell.homeManagerModules.default
    ./browser.nix
    ./mimeapps.nix
    ./hyprland.nix
  ];

  programs.codexDesktopLinux = {
    enable = true;
    cliPackage = codexCli;
  };

  home.file."Pictures/Wallpapers" = {
    source = ./wallpapers;
    recursive = true;
  };

  home.activation.obsidianVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        vault="${config.home.homeDirectory}/Documents/Obsidian"
        ignore="$vault/.stignore"

        $DRY_RUN_CMD mkdir -p "$vault"
        if [ ! -e "$ignore" ]; then
          $DRY_RUN_CMD tee "$ignore" >/dev/null <<'EOF'
    .obsidian/workspace.json
    .obsidian/workspace-mobile.json
    .obsidian/workspace-*.json
    .obsidian/cache/
    .trash/
    EOF
        fi
  '';

  home.file.".aws/config".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/local/aws/config";
  home.file.".aws/credentials".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/secrets/aws/credentials";

  programs.caelestia = {
    enable = true;
    package = patchedCaelestiaShell;
    systemd.enable = false;
    cli.enable = true;
    settings = {
      general.apps = {
        terminal = [ "foot" ];
        audio = [ "pavucontrol" ];
        explorer = [ "dolphin" ];
      };
      paths.wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
      services.smartScheme = true;
      appearance.transparency.enabled = false;
    };
    cli.settings = {
      theme = {
        enableGtk = true;
        enableQt = true;
        # After Caelestia updates generated theme files, sync toolkit settings for native apps.
        postHook = "caelestia-sync-gtk-settings";
      };
    };
  };

  # force=true: HM must overwrite writable copies from the previous activation.
  # activation: replace read-only store symlinks so Caelestia can auto-save at runtime.
  xdg.configFile."caelestia/shell.json".force = true;
  xdg.configFile."caelestia/cli.json".force = true;
  home.activation.caelestiaWritableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    caelestiaDir="${config.home.homeDirectory}/.config/caelestia"
    $DRY_RUN_CMD mkdir -p "$caelestiaDir"
    $DRY_RUN_CMD rm -f "$caelestiaDir/shell.json" "$caelestiaDir/cli.json"
    $DRY_RUN_CMD cp ${config.xdg.configFile."caelestia/shell.json".source} "$caelestiaDir/shell.json"
    $DRY_RUN_CMD cp ${config.xdg.configFile."caelestia/cli.json".source} "$caelestiaDir/cli.json"
    $DRY_RUN_CMD chmod u+w "$caelestiaDir/shell.json" "$caelestiaDir/cli.json"
  '';

  xdg.dataFile."applications/org.kde.plasma-systemmonitor.desktop" = {
    force = true;
    text =
      builtins.replaceStrings
        [ "Exec=plasma-systemmonitor" ]
        [
          "Exec=env QT_QPA_PLATFORMTHEME=kde QT_QPA_PLATFORM=wayland GDK_BACKEND=wayland,x11 plasma-systemmonitor"
        ]
        (
          builtins.readFile "${pkgs.kdePackages.plasma-systemmonitor}/share/applications/org.kde.plasma-systemmonitor.desktop"
        );
  };

  xdg.desktopEntries.zen-vault = {
    name = "Zen Browser (Vault)";
    genericName = "Private Web Browser";
    comment = "Launch Zen with its profile stored inside the VeraCrypt vault";
    exec = "zen-vault %U";
    icon = "zen-browser";
    categories = [
      "Network"
      "WebBrowser"
      "Security"
    ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  # KDE: System Settings > Keyboard > NumLock on startup = Turn on
  xdg.configFile."kcminputrc".text = ''
    [Keyboard]
    NumLock=0
  '';

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "zen-beta";
    ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
    ANDROID_SDK_ROOT = "${config.home.homeDirectory}/Android/Sdk";
    XDG_MENU_PREFIX = "plasma-";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.config/emacs/bin"
  ];

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
    includes = [
      { path = "/etc/nixos/local/gitconfig"; }
    ];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };

  programs.zsh = {
    shellAliases = {
      ll = "ls -lah";
      gs = "git status";
      vi = "nvim";
      vim = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#${hostname}";
      test-rebuild = "sudo nixos-rebuild test --flake /etc/nixos#${hostname}";
      codex-login = "codex login --device-auth";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    escapeTime = 10;
    historyLimit = 100000;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];

    extraConfig = ''
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g focus-events on
      set -g set-clipboard on
      set -as terminal-overrides ',*:RGB'

      bind C-a send-prefix
      set -g prefix2 C-b
      bind C-b send-prefix
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      bind | split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5

      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"

      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'
      set -g @resurrect-capture-pane-contents 'on'
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

  programs.zoxide = {
    enable = true;
    enableFishIntegration = false; # Caelestia's fish config is patched below.
    enableZshIntegration = true;
    options = [ "--cmd z" ];
  };

  programs.ssh = {
    enable = true;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
    };
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
      identitiesOnly = true;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };

  home.activation.doomEmacsStarter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    emacsDir="${config.home.homeDirectory}/.config/emacs"
    doomBin="$emacsDir/bin/doom"

    if [ ! -x "$doomBin" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$emacsDir")"
      if [ -e "$emacsDir" ]; then
        backup="$emacsDir.backup-before-doom-$(date +%Y%m%d%H%M%S)"
        $DRY_RUN_CMD mv "$emacsDir" "$backup"
      fi
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/doomemacs/doomemacs "$emacsDir" || true
    fi

    if [ -d "$emacsDir/.git" ] && [ ! -d "$emacsDir/sources/doom+/modules" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$emacsDir" submodule update --init --recursive --depth 1 || true
    fi
  '';

  home.activation.nvchadStarter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nvimDir="${config.home.homeDirectory}/.config/nvim"
    initLua="$nvimDir/init.lua"

    if [ -L "$initLua" ] && readlink "$initLua" | grep -q '/nix/store/'; then
      $DRY_RUN_CMD rm -rf "$nvimDir"
    fi

    if [ ! -e "$initLua" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$nvimDir")"
      if [ -e "$nvimDir" ]; then
        backup="$nvimDir.backup-before-nvchad-$(date +%Y%m%d%H%M%S)"
        $DRY_RUN_CMD mv "$nvimDir" "$backup"
      fi
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/NvChad/starter "$nvimDir" || true
    fi
  '';

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "zen-vault";
      runtimeInputs = [ coreutils ];
      text = ''
        vault=
        for candidate in /run/media/veracrypt1 /tmp/veracrypt_mnt1; do
          if mountpoint -q "$candidate"; then
            vault="$candidate"
            break
          fi
        done

        if [ -z "$vault" ]; then
          printf 'VeraCrypt vault is not mounted at /run/media/veracrypt1 or /tmp/veracrypt_mnt1\n' >&2
          printf 'Mount your VeraCrypt container first, then run zen-vault again.\n' >&2
          exit 1
        fi

        profile="$vault/zen-profile"
        downloads="$vault/Downloads"

        mkdir -p "$profile" "$downloads"
        cat > "$profile/user.js" <<EOF
        user_pref("browser.download.folderList", 2);
        user_pref("browser.download.dir", "$downloads");
        user_pref("browser.download.useDownloadDir", true);
        EOF

        exec zen-beta --new-instance --profile "$profile" "$@"
      '';
    })
    (writeShellApplication {
      name = "doom";
      text = ''
        exec "$HOME/.config/emacs/bin/doom" "$@"
      '';
    })
    neovim
    lazygit
    jq
    yq
    eza
    bat
    fzf
    ripgrep
    fd
    wl-clipboard
    yazi
  ];
}
