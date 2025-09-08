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
        {
          users.users."${user}".home = "/home/${user}";
          home-manager.users."${user}" = homeManagerConfig;
          home-manager.extraSpecialArgs = {
            inherit inputs;
            pkgs = import nixpkgs-unstable { inherit system; };
          };
        }
      ];
      specialArgs = { inherit inputs; };
    };

}
