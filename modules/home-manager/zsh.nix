{ lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = lib.mkDefault true;
    syntaxHighlighting.enable = true;
    initContent = lib.mkDefault ''
      bindkey -e
    '';
  };
}
