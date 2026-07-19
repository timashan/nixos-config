{ ... }:

{
  xdg.configFile."herdr/config.toml" = {
    force = true;
    text = ''
      [keys]
      prefix = "ctrl+a"
    '';
  };
}
