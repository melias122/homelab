{
  description = "A flake template for nix-darwin and Determinate Nix";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.1";
  };

  outputs =
    { self, ... }@inputs:
    let
      username = "m";
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations."MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          inputs.determinate.darwinModules.default
          self.darwinModules.base
          self.darwinModules.nixConfig
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;

              # Also installs the Intel prefix for Rosetta 2.
              enableRosetta = true;

              user = username;
            };
          }

          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }

          (
            {
              config,
              pkgs,
              lib,
              ...
            }:
            {
              # Required by nix-homebrew.
              system.primaryUser = username;
              homebrew = {
                enable = true;
                casks = [
                  "beekeeper-studio"
                  "bruno"
                  "emacs-app"
                  "google-chrome"
                  "insomnia"
                  "opencode-desktop"
                  "redis-insight"
                  "tailscale-app"
                  "the-unarchiver"
                  "visual-studio-code"
                  "karabiner-elements"
                  "steam"
                ];

                brews = [
                  "colima"
                  "gh"
                  "go"
                  "gopls"
                  "mise"
                  "npm"
                  "opencode"
                ];

                onActivation.cleanup = "zap";
                onActivation.autoUpdate = true;
                onActivation.upgrade = true;
              };

              environment.variables = {
                GOPRIVATE = "github.com/corwyn-com,github.com/oddin-gg";
              };

              environment.variables = {
                TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
                DOCKER_HOST = "unix://\${HOME}/.colima/docker.sock";
              };

              system.defaults = {
                dock = {
                  autohide = true;
                  orientation = "left";
                };
              };
            }
          )
        ];
      };

      darwinModules = {
        base =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            system.stateVersion = 1;

            users.users.${username} = {
              name = username;
            };
          };

        nixConfig =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            nixpkgs.config.allowUnfree = true;

            # Determinate manages nix itself.
            nix.enable = false;

            determinateNix.customSettings = {
              eval-cores = 0;
              extra-experimental-features = [
                "build-time-fetch-tree"
                "parallel-eval"
              ];
            };

            fonts.packages = with pkgs; [
              fira-code
              fira-code-symbols
              ibm-plex
            ];

            environment.systemPackages = with pkgs; [
              alacritty
              awscli2
              colima
              delta
              docker
              docker-compose
              editorconfig-core-c
              git
              git-extras
              gnumake
              nodejs
              terraform
              terraform-ls
              ripgrep
              yarn
            ];
          };
      };

      devShells.${system}.default =
        let
          pkgs = import inputs.nixpkgs { inherit system; };
        in
        pkgs.mkShellNoCC {
          packages = with pkgs; [
            (writeShellApplication {
              name = "apply-nix-darwin-configuration";
              runtimeInputs = [
                inputs.nix-darwin.packages.${system}.darwin-rebuild
              ];
              text = ''
                echo "> Applying nix-darwin configuration..."

                echo "> Running darwin-rebuild switch as root..."
                sudo darwin-rebuild switch --flake ./machines/MacBook-Air
                echo "> darwin-rebuild switch was successful ✅"

                echo "> macOS config was successfully applied 🚀"
              '';
            })

            self.formatter.${system}
          ];
        };

      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
