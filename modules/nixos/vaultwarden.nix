{ ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";

    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      # Local trial mode: create the first account before exposing the service.
      SIGNUPS_ALLOWED = true;
    };
  };
}
