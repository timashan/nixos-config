{
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/base.nix
    ../../modules/home-manager/herdr.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
  ];

  home.username = "private";
  home.homeDirectory = "/home/private";

  programs.zsh = {
    autosuggestion.enable = false;
    initContent = ''
      unset HISTFILE
      HISTSIZE=0
      SAVEHIST=0
      setopt HIST_NO_STORE
    '';
  };

  programs.tmux = {
    historyLimit = 1000;
  };

  home.packages = with pkgs; [
    yt-dlp
    ffmpeg-full
  ];
}
