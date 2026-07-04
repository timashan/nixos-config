{
  pkgs,
  ...
}:

{
  home.username = "private";
  home.homeDirectory = "/home/private";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = true;
    initContent = ''
      unset HISTFILE
      HISTSIZE=0
      SAVEHIST=0
      setopt HIST_NO_STORE
    '';
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 1000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    sensibleOnTop = true;
    terminal = "tmux-256color";
  };

  home.packages = with pkgs; [
    yt-dlp
    ffmpeg-full
  ];
}
