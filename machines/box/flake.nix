{
  description = "NixOS configuration for box machine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # No nixpkgs follows: keeps their CI-tested pin and cache.numtide.com hits.
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, llm-agents, ... }: let
    system = "x86_64-linux";

    # Shared by the pkgs below and the NixOS module system, which builds its own pkgs.
    permittedInsecurePackages = [
      "beekeeper-studio-6.0.5"
      "electron-41.10.6"
    ];

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = permittedInsecurePackages;
    };
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = permittedInsecurePackages;
    };
    agents = llm-agents.packages.${system};
  in {
    homeConfigurations = {
      melias122 = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit unstable agents; };
        modules = [
          ../../users/melias122
        ];
      };
    };

    nixosConfigurations = {
      box = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./.
          { nixpkgs.config.permittedInsecurePackages = permittedInsecurePackages; }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit unstable agents; };
            home-manager.users.melias122 = import ../../users/melias122;
          }
        ];
      };
    };
  };
}
