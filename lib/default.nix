{
  nixpkgs,
  nixpkgs-unstable,
  home-manager-unstable,
  stateVersion,
  inputs,
  secrets,
  agenix,
  nixidy,
}:
let
  homeManagerConfig = import ../home {
    pkgs = nixpkgs;
    inherit inputs;
  };
in
{
  linuxSystem =
    {
      system,
      host,
      user,
      stateVersion,
      homeManagerConfig,
    }:
    nixpkgs-unstable.lib.nixosSystem {
      inherit system;
      modules = [
        (
          { config, ... }:
          {
            config.system.stateVersion = stateVersion;
          }
        )
        (../hosts + "/${host}/configuration.nix")
        (../hosts + "/${host}/services")
        agenix.nixosModules.default
        secrets.nixosModules.secrets
        {
          secrets.enable = true;
        }
        home-manager-unstable.nixosModules.home-manager
        (
          let
            pkgs = import nixpkgs-unstable { inherit system; };
          in
          {
            users.users."${user}".home = "/home/${user}";
            home-manager.users."${user}" = homeManagerConfig {
              inherit pkgs;
            };
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit pkgs;
            };
          }
        )
      ];
      specialArgs = { inherit inputs; };
    };

}
