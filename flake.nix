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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      codex-desktop-linux,
      codex-cli-nix,
      zen-browser,
      caelestia-shell,
      caelestia-dots,
      ...
    }:
    let
      system = "x86_64-linux";
      hostname = "tuf-a15";
      username = "timashan";
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
          inherit hostname username codexCli;
        };

        modules = [
          ./hosts/tuf-a15

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit
                hostname
                username
                codex-desktop-linux
                codexCli
                zen-browser
                caelestia-shell
                caelestia-dots
                ;
            };
            home-manager.users.${username} = import ./home/timashan/home.nix;
            home-manager.users.private = import ./home/private/home.nix;
          }
        ];
      };
    };
}
