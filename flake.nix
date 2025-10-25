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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      disko,
      ...
    }:
    let
      system = "x86_64-linux";
      hosts = [
        "homelab-01"
        "homelab-02"
        "homelab-03"
      ];
      mkHomelabNode =
        hostName:

        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            secrets.nixosModules.secrets
            {
              secrets.enable = true;
            }
            (import ./hosts/homelab/configuration.nix {
              inherit hostName;
              nodeRole = "server";
              zigbeeNode = hostName == (builtins.elemAt hosts 0);
              k3s_init = hostName == (builtins.elemAt hosts 0);
            })
          ];
        };
    in
    {
      nixosConfigurations = (nixpkgs.lib.genAttrs hosts mkHomelabNode) // {
        tv = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            ./hosts/tv/configuration.nix
          ];
        };
      };
    }
    // (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        unstable = import nixpkgs-unstable { inherit system; };
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
              "traefik-crds/crds-files/traefik/traefik.io_middlewares.yaml"
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

          generators.cert-manager = nixidy.packages.${system}.generators.fromCRD {
            name = "cert-manager";
            src = pkgs.fetchFromGitHub {
              owner = "cert-manager";
              repo = "cert-manager";
              rev = "v1.19.0";
              hash = "";
            };
            crds = [
              "deploy/crds/cert-manager.io_certificaterequests.yaml"
              "deploy/crds/cert-manager.io_certificates.yaml"
              "deploy/crds/cert-manager.io_clusterissuers.yaml"
              "deploy/crds/cert-manager.io_issuers.yaml"
            ];
          };

        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ nixidy.packages.${system}.default ];
          packages = with pkgs; [
            argocd
            k9s
            kubectl
            popeye
            postgresql_17
            unstable.nixos-anywhere
            unstable.nixos-rebuild
            unstable.renovate
            wireguard-tools
          ];
        };
      }
    ));
}
