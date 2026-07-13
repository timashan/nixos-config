{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # Needed for NVIDIA, Steam, Discord, VS Code, Cursor, and Android Studio.
  nixpkgs.config.allowUnfree = true;
  # Codex Desktop (and some Electron apps) depend on EOL Electron builds.
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
    # OpenClaw is marked insecure because agents can be prompt-injected by
    # untrusted content while running with the user's system access.
    "openclaw-2026.5.7"
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
    timeout = 5;
  };

  boot.kernelModules = [ "kvm-amd" ];
  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  time.timeZone = "Asia/Colombo";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Keep setuid/setcap wrappers ahead of the plain package binaries in shells
  # spawned outside the normal login profile setup, such as editor terminals.
  environment.localBinInPath = true;
  environment.extraInit = ''
    case ":$PATH:" in
      *:/run/wrappers/bin:*) ;;
      *) export PATH="/run/wrappers/bin:$PATH" ;;
    esac
  '';

  services.dbus.enable = true;
  services.fwupd.enable = true;
  services.fstrim.enable = true;
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # zram gives this 16 GB laptop more breathing room without requiring a swap
  # partition. Add a swapfile later if hibernation becomes a requirement.
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  services.udev.packages = with pkgs; [
    game-devices-udev-rules
  ];

  environment.systemPackages = with pkgs; [
    bash-completion
    curl
    wget
    vim
    nano
    pciutils
    usbutils
    lshw
    dmidecode
    inxi
    hwinfo
    lm_sensors
    smartmontools
    nvme-cli
    powertop
    btop
    htop
    gum
    jq
    ripgrep
    fd
    tree
    file
    which
  ];
}
