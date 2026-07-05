{ ... }:

let
  mkAmoExtension = slug: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
    installation_mode = "force_installed";
  };
in
{
  home.file."/home/timashan/.config/zen/profiles.ini".force = true;

  programs.zen-browser = {
    enable = true;

    policies.ExtensionSettings = {
      "uBlock0@raymondhill.net" = mkAmoExtension "ublock-origin";
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkAmoExtension "bitwarden-password-manager";
      "addon@darkreader.org" = mkAmoExtension "darkreader";
      "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = mkAmoExtension "video-downloadhelper";
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = mkAmoExtension "return-youtube-dislikes";
      "sponsorBlocker@ajay.app" = mkAmoExtension "sponsorblock";
      "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack" = mkAmoExtension "grammarly-1";
    };

    profiles."Default Profile" = {
      path = "cr3ad36v.Default Profile";

      settings = {
        "browser.bookmarks.file" = "/etc/nixos/local/bookmarks.html";
        "browser.places.importBookmarksHTML" = true;
        "browser.toolbars.bookmarks.visibility" = "always";
        "extensions.autoDisableScopes" = 0;
      };
    };
  };
}
