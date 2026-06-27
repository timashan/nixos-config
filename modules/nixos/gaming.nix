{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  hardware.steam-hardware.enable = true;

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    wineWow64Packages.stable
    winetricks
    protontricks
    protonup-qt
    lutris
    heroic
    bottles
    mangohud
    goverlay
    gamescope
    gamemode
  ];
}
