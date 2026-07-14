{ pkgs, ... }:

let
  alc256MicProfile = pkgs.writeText "tuf-a15-alc256.conf" ''
    ${builtins.readFile "${pkgs.pipewire}/share/alsa-card-profile/mixer/profile-sets/default.conf"}

    [DecibelFix Capture]
    db-values = 0:-96.00 31:0.00
  '';
in
{
  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-tuf-a15-alc256-mic.conf" ''
      monitor.alsa.rules = [
        {
          matches = [
            {
              device.name = "alsa_card.pci-0000_36_00.6"
            }
          ]
          actions = {
            update-props = {
              device.profile-set = "tuf-a15-alc256.conf"
              api.alsa.ignore-dB = true
            }
          }
        }
      ]
    '')
  ];

  environment.etc."alsa-card-profile/mixer/profile-sets/tuf-a15-alc256.conf".source =
    alc256MicProfile;
}
