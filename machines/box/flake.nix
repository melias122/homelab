{
  description = "NixOS configuration for box machine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, nixos-hardware, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # home-manager only config
    homeConfigurations = {
      melias122 = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ../../users/melias122
        ];
      };
    };

    nixosConfigurations = {
      box = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.melias122 = import ../../users/melias122;
          }
        ];
      };
    };
  };
}
