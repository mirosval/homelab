{
  description = "Miro's homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      # This pattern is because the repo is private
      # it relies on git being configured with gh auth setup-git
      url = "git+https://github.com/mirosval/secrets.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixidy.url = "github:arnarg/nixidy";
    flake-utils.url = "github:numtide/flake-utils";
    mirosval.url = "github:mirosval/dotfiles";
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      agenix,
      secrets,
      nixidy,
      flake-utils,
      mirosval,
      ...
    }:
    let
      stateVersion = "25.05";
      lib = import ./lib {
        inherit
          nixpkgs
          nixpkgs-unstable
          home-manager
          stateVersion
          inputs
          secrets
          agenix
          nixidy
          ;
      };
    in
    {
      nixosConfigurations = {
        homelab-01 = lib.linuxSystem {
          inherit stateVersion;
          system = "x86_64-linux";
          host = "homelab-01";
          user = "miro";
          homeManagerConfig = mirosval.lib.home;
        };
      };
    }
    // (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {

        nixidyEnvs = nixidy.lib.mkEnvs {
          inherit pkgs;
          envs = {
            homelab.modules = [ ./k3s/definitions ];
          };
        };

        packages = {
          nixidy = nixidy.packages.${system}.default;

          generators.metallb = nixidy.packages.${system}.generators.fromCRD {
            name = "metallb";
            src = pkgs.fetchFromGitHub {
              owner = "metallb";
              repo = "metallb";
              rev = "v0.15";
              hash = "sha256-7jptqytou6Rv4BTcHIzFh++o/O8ojL7Z9b1fHWwQl+U=";
            };
            crds = [
              "config/manifests/metallb-native.yaml"
            ];
          };

          generators.traefik = nixidy.packages.${system}.generators.fromCRD {
            name = "traefik";
            src = pkgs.fetchFromGitHub {
              owner = "traefik";
              repo = "traefik-helm-chart";
              rev = "crds_v1.11.0";
              hash = "sha256-hk68hR2sBnJUC3iwYoNs9hdvbHz40OHU9gtnrAyRMoE=";
            };
            crds = [
              "traefik-crds/crds-files/traefik/traefik.io_ingressroutes.yaml"
            ];
          };

          generators.cnpg = nixidy.packages.${system}.generators.fromCRD {
            name = "cloudnative-pg";
            src = pkgs.fetchFromGitHub {
              owner = "cloudnative-pg";
              repo = "cloudnative-pg";
              rev = "v1.27.0";
              hash = "sha256-GDPVrGWawzuOjTCtXIDFH2XUQ6Ot3i+w4x61QK3TyIE=";
            };
            crds = [
              "releases/cnpg-1.27.0.yaml"
            ];
          };

        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ nixidy.packages.${system}.default ];
          packages = with pkgs; [
            k9s
            kubectl
            popeye
            renovate
          ];
        };
      }
    ));
}
