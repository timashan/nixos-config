{
  config,
  lib,
  pkgs,
  ...
}:

let
  mkAmoExtension = slug: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
    installation_mode = "force_installed";
  };

  bookmarksHtml = "/etc/nixos/local/bookmarks.html";
  heliumExtensions = pkgs.callPackage ../../packages/helium-extensions { };
  seedHelium = pkgs.writeShellApplication {
    name = "seed-helium-profile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.python3
    ];
    text = ''
      export HELIUM_BOOKMARK_CONVERTER=${./netscape-to-chromium-bookmarks.py}
      export HELIUM_EXTENSIONS_DIR=${heliumExtensions}
      python3 ${./seed-helium-profile.py}
    '';
  };
in
{
  home.file."${config.home.homeDirectory}/.config/zen/profiles.ini".force = true;

  home.activation.heliumBookmarks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${lib.getExe seedHelium}
  '';

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
        "browser.bookmarks.file" = bookmarksHtml;
        "browser.places.importBookmarksHTML" = true;
        "browser.toolbars.bookmarks.visibility" = "always";
        "extensions.autoDisableScopes" = 0;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
      };
    };
  };
}
