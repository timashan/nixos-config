{
  lib,
  pkgs,
  username,
  ...
}:

let
  repository = {
    repository = "rclone:gdrive:nixos-backups";
    passwordFile = "/etc/nixos/secrets/restic/password";
    rcloneConfigFile = "/etc/nixos/secrets/restic/rclone.conf";
    rcloneOptions = {
      tpslimit = "4";
      tpslimit-burst = "4";
    };
  };
  excludedDirectories = [
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
  pruneDirectories = lib.concatMapStringsSep " -o " (
    name: "-name ${lib.escapeShellArg name}"
  ) excludedDirectories;
in

{
  services.restic.backups.nixos-backups = repository // {
    initialize = true;
    extraBackupArgs = [ "--retry-lock=30m" ];

    paths = [
      "/etc/nixos/hosts"
      "/etc/nixos/local"
      "/etc/nixos/secrets"
      "/var/backup/vaultwarden"
      "/home/${username}/Documents/Vaults"
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
          ${pkgs.findutils}/bin/find "$root" \
            \( -type d \( ${pruneDirectories} \) -prune \) -o \
            \( -type f \
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
            ! -name '*.template.tfvars.json' -print \)
        fi
      done

      zenDir="/home/${username}/.config/zen"
      if [ -d "$zenDir" ]; then
        # Profiles are direct children; avoid walking browser caches/storage.
        for profile in "$zenDir"/*; do
          [ -d "$profile" ] || continue
          for name in places.sqlite places.sqlite-wal places.sqlite-shm; do
            if [ -f "$profile/$name" ]; then
              printf '%s\n' "$profile/$name"
            fi
          done
          if [ -d "$profile/bookmarkbackups" ]; then
            ${pkgs.findutils}/bin/find "$profile/bookmarkbackups" -type f
          fi
        done
      fi
    '';

    exclude = excludedDirectories;

    timerConfig = {
      OnCalendar = "23:30";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  # Maintenance has no backup paths: retain daily backups, but perform the
  # expensive repository sweep and data verification only once a week.
  services.restic.backups.nixos-maintenance = repository // {
    timerConfig = {
      OnCalendar = "Sun 02:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
    pruneOpts = [
      "--retry-lock=30m"
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];

    checkOpts = [
      "--retry-lock=30m"
      "--read-data-subset=1G"
    ];
  };

  systemd.services =
    lib.genAttrs
      [
        "restic-backups-nixos-backups"
        "restic-backups-nixos-maintenance"
      ]
      (_: {
        path = [ pkgs.rclone ];
        serviceConfig = {
          Nice = 10;
          IOSchedulingClass = "idle";
          IOWeight = 50;
        };
      });

  environment.systemPackages = with pkgs; [
    rclone
    restic
  ];
}
