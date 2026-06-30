{ pkgs, ... }:

let
  mkDefaults =
    desktop: mimeTypes:
    builtins.listToAttrs (
      map (mimeType: {
        name = mimeType;
        value = [ desktop ];
      }) mimeTypes
    );

  imageDefaults = mkDefaults "org.kde.gwenview.desktop" [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heif"
    "image/jpeg"
    "image/jxl"
    "image/png"
    "image/svg+xml"
    "image/svg+xml-compressed"
    "image/tiff"
    "image/webp"
    "image/x-webp"
  ];

  mediaDefaults = mkDefaults "vlc.desktop" [
    "audio/aac"
    "audio/flac"
    "audio/mpeg"
    "audio/ogg"
    "audio/wav"
    "audio/webm"
    "audio/x-m4a"
    "audio/x-wav"
    "video/avi"
    "video/mp4"
    "video/mpeg"
    "video/quicktime"
    "video/webm"
    "video/x-avi"
    "video/x-flv"
    "video/x-matroska"
    "video/x-msvideo"
    "video/x-ms-wmv"
    "video/x-theora+ogg"
  ];

  appDefaults = {
    "application/pdf" = [ "okularApplication_pdf.desktop" ];
    "application/json" = [ "micro.desktop" ];
    "application/x-shellscript" = [ "micro.desktop" ];
    "inode/directory" = [ "org.kde.dolphin.desktop" ];
    "text/markdown" = [ "okularApplication_md.desktop" ];
    "text/plain" = [ "micro.desktop" ];
    "text/x-csrc" = [ "micro.desktop" ];
    "text/x-c++src" = [ "micro.desktop" ];
    "text/x-python" = [ "micro.desktop" ];
    "text/x-shellscript" = [ "micro.desktop" ];
    "x-scheme-handler/http" = [ "zen-beta.desktop" ];
    "x-scheme-handler/https" = [ "zen-beta.desktop" ];
    "x-scheme-handler/chrome" = [ "zen-beta.desktop" ];
    "text/html" = [ "zen-beta.desktop" ];
    "application/x-extension-htm" = [ "zen-beta.desktop" ];
    "application/x-extension-html" = [ "zen-beta.desktop" ];
    "application/x-extension-shtml" = [ "zen-beta.desktop" ];
    "application/xhtml+xml" = [ "zen-beta.desktop" ];
    "application/x-extension-xhtml" = [ "zen-beta.desktop" ];
    "application/x-extension-xht" = [ "zen-beta.desktop" ];
    "x-scheme-handler/bitwarden" = [ "bitwarden.desktop" ];
  };

  defaults = imageDefaults // mediaDefaults // appDefaults;
in
{
  xdg.configFile."mimeapps.list".force = true;
  xdg.configFile."environment.d/10-xdg-menu-prefix.conf".text = ''
    XDG_MENU_PREFIX=plasma-
  '';
  xdg.configFile."menus/applications.menu" = {
    source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
    force = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = defaults;
    associations.added = defaults // {
      "x-scheme-handler/bitwarden" = [
        "bitwarden.desktop"
        "Bitwarden.desktop"
      ];
    };
  };
}
