{
  description = "A flake template for nix-darwin and Determinate Nix";

  # Flake inputs
  inputs = {
    # Stable Nixpkgs (use 0.1 for unstable)
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    # Stable nix-darwin (use 0.1 for unstable)
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Determinate 3.* module
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  # Flake outputs
  outputs =
    { self, ... }@inputs:
    let
      username = "m";
      system = "aarch64-darwin";
    in
    {
      # nix-darwin configuration output
      darwinConfigurations."MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # Add the determinate nix-darwin module
          inputs.determinate.darwinModules.default
          # Apply the modules output by this flake
          self.darwinModules.base
          self.darwinModules.nixConfig
          # Apply any other imported modules here
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = username;
            };
          }
          # In addition to adding modules in the style above, you can also
          # add modules inline like this. Delete this if unnecessary.
          (
            {
              config,
              pkgs,
              lib,
              ...
            }:
            {
              fonts.packages = with pkgs; [
                fira-code
                fira-code-symbols
                ibm-plex
              ];

              # Needs to be set for nix-homebrew
              system.primaryUser = username;
              homebrew = {
                enable = true;
                casks = [
                  "beekeeper-studio"
                  "emacs-app"
                  "google-chrome"
                  "insomnia"
                  "redis-insight"
                  "tailscale-app"
                  "the-unarchiver"
                  "tunnelblick"
                  "visual-studio-code"
                ];

                # Ensures only packages specified in homebrew configurations are installed
                onActivation.cleanup = "zap";
                onActivation.autoUpdate = true;
                onActivation.upgrade = true;
              };

              environment.systemPackages = with pkgs; [
                alacritty
                delta
                git
                git-extras
                gnumake
                nodejs
                ripgrep
                yarn
              ];

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

      # nix-darwin module outputs
      darwinModules = {
        # Some base configuration
        base =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            # Required for nix-darwin to work
            system.stateVersion = 1;

            users.users.${username} = {
              name = username;
              # See the reference docs for more on user config:
              # https://nix-darwin.github.io/nix-darwin/manual/#opt-users.users
            };

            # Other configuration parameters
            # See here: https://nix-darwin.github.io/nix-darwin/manual
          };

        # Nix configuration
        nixConfig =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            # Let Determinate Nix handle your Nix configuration
            nix.enable = false;

            # Custom Determinate Nix settings written to /etc/nix/nix.custom.conf
            determinate-nix.customSettings = {
              # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
              eval-cores = 0;
              extra-experimental-features = [
                "build-time-fetch-tree" # Enables build-time flake inputs
                "parallel-eval" # Enables parallel evaluation
              ];
              # Other settings
            };
          };

        # Add other module outputs here
      };

      # Development environment
      devShells.${system}.default =
        let
          pkgs = import inputs.nixpkgs { inherit system; };
        in
        pkgs.mkShellNoCC {
          packages = with pkgs; [
            # Shell script for applying the nix-darwin configuration.
            # Run this to apply the configuration in this flake to your macOS system.
            (writeShellApplication {
              name = "apply-nix-darwin-configuration";
              runtimeInputs = [
                # Make the darwin-rebuild package available in the script
                inputs.nix-darwin.packages.${system}.darwin-rebuild
              ];
              text = ''
                echo "> Applying nix-darwin configuration..."

                echo "> Running darwin-rebuild switch as root..."
                sudo darwin-rebuild switch --flake .
                echo "> darwin-rebuild switch was successful ✅"

                echo "> macOS config was successfully applied 🚀"
              '';
            })

            self.formatter.${system}
          ];
        };

      # Nix formatter

      # This applies the formatter that follows RFC 166, which defines a standard format:
      # https://github.com/NixOS/rfcs/pull/166

      # To format all Nix files:
      # git ls-files -z '*.nix' | xargs -0 -r nix fmt
      # To check formatting:
      # git ls-files -z '*.nix' | xargs -0 -r nix develop --command nixfmt --check
      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
