{
  description = "NixOS configuration for box machine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, ... }: let
    system = "x86_64-linux";

    # Single source of truth, referenced by both `pkgs` below and the
    # NixOS configuration (which builds its own pkgs from the module system).
    permittedInsecurePackages = [ ];

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = permittedInsecurePackages;
    };
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # home-manager only config
    homeConfigurations = {
      melias122 = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit unstable; };
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
            home-manager.extraSpecialArgs = { inherit unstable; };
            home-manager.users.melias122 = import ../../users/melias122;
          }
        ];
      };
    };
  };
}
