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

        packages.nixidy = nixidy.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          buildInputs = [ nixidy.packages.${system}.default ];
          packages = with pkgs; [
            kubectl
            k9s
          ];
        };
      }
    ));
}
