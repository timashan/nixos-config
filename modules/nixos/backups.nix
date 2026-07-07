{ pkgs, username, ... }:

{
  services.restic.backups.nixos-backups = {
    initialize = true;
    repository = "rclone:gdrive:nixos-backups";
    passwordFile = "/etc/nixos/secrets/restic/password";
    rcloneConfigFile = "/etc/nixos/secrets/restic/rclone.conf";
    rcloneOptions = {
      tpslimit = "4";
      tpslimit-burst = "4";
    };

    paths = [
      "/etc/nixos/local"
      "/etc/nixos/secrets"
      "/var/backup/vaultwarden"
      "/home/${username}/Documents/Obsidian"
      "/home/${username}/.justfile"
    ];

    dynamicFilesFrom = ''
      set -eu

      for root in \
        "/home/${username}/code" \
        "/home/${username}/dev" \
        "/home/${username}/projects" \
        "/home/${username}/work"
      do
        if [ -d "$root" ]; then
          ${pkgs.findutils}/bin/find "$root" -type f \
            \( \
              -name '.env' \
              -o -name '.env.*' \
              -o -name '*.tfvars' \
              -o -name '*.tfvars.json' \
              -o -iname 'justfile' \
              -o -name '.justfile' \
              -o -name '*.just' \
            \) \
            ! -name '.env.example' \
            ! -name '.env.sample' \
            ! -name '.env.template' \
            ! -name '*.example.tfvars' \
            ! -name '*.sample.tfvars' \
            ! -name '*.template.tfvars' \
            ! -name '*.example.tfvars.json' \
            ! -name '*.sample.tfvars.json' \
            ! -name '*.template.tfvars.json'
        fi
      done

      zenDir="/home/${username}/.config/zen"
      if [ -d "$zenDir" ]; then
        ${pkgs.findutils}/bin/find "$zenDir" -type f \
          \( \
            -name 'places.sqlite' \
            -o -name 'places.sqlite-wal' \
            -o -name 'places.sqlite-shm' \
            -o -path '*/bookmarkbackups/*' \
          \)
      fi
    '';

    exclude = [
      ".git"
      "node_modules"
      ".direnv"
      ".venv"
      "venv"
      "target"
      "dist"
      "build"
      ".next"
      ".turbo"
    ];

    timerConfig = {
      OnCalendar = "23:30";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };

    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];

    checkOpts = [
      "--read-data-subset=1G"
    ];
  };

  systemd.services.restic-backups-nixos-backups.path = [
    pkgs.rclone
  ];

  environment.systemPackages = with pkgs; [
    rclone
    restic
  ];
}
