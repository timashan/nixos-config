{
  description = "Production-oriented NixOS config for ASUS TUF Gaming A15 FA507NU";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:nousresearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-dots = {
      url = "github:caelestia-dots/caelestia";
      flake = false;
    };

    localConfig = {
      url = "path:/etc/nixos/local/settings.nix";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      codex-desktop-linux,
      codex-cli-nix,
      claude-desktop,
      hermes-agent,
      zen-browser,
      caelestia-shell,
      caelestia-dots,
      localConfig,
      ...
    }:
    let
      localSettings = import localConfig;
      system = "x86_64-linux";
      hostname = localSettings.hostname or "default";
      host = localSettings.host or hostname;
      hostPath = ./hosts + "/${host}";
      username = localSettings.username or "admin";
      pkgs = nixpkgs.legacyPackages.${system};
      codexCli = codex-cli-nix.packages.${system}.default;
    in
    {
      formatter.${system} = pkgs.writeShellApplication {
        name = "nixfmt";
        runtimeInputs = [
          pkgs.findutils
          pkgs.git
          pkgs.nixfmt
        ];
        text = ''
          if [ "$#" -gt 0 ]; then
            exec nixfmt "$@"
          fi

          if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git ls-files '*.nix' -z | xargs -0 --no-run-if-empty nixfmt
          else
            find . -type f -name '*.nix' -not -path './.git/*' -print0 | xargs -0 --no-run-if-empty nixfmt
          fi
        '';
      };

      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            hostname
            username
            codexCli
            claude-desktop
            hermes-agent
            ;
        };

        modules = [
          hostPath

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit
                hostname
                codex-desktop-linux
                codexCli
                zen-browser
                caelestia-shell
                caelestia-dots
                ;
            };
          }
        ];
      };
    };
}
