{
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  stateVersion,
  inputs,
  secrets,
  agenix,
  nixidy,
}:
{
  homelabHost =
    {
      system,
      hostName,
      user,
      stateVersion,
      homeManagerConfig,
      nodeRole ? "server",
      zigbeeNode ? false,
    }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        (
          { config, ... }:
          {
            config.system.stateVersion = stateVersion;
          }
        )
        (import ./homelab-host.nix { inherit hostName nodeRole zigbeeNode; })
        agenix.nixosModules.default
        secrets.nixosModules.secrets
        {
          secrets.enable = true;
        }
        home-manager.nixosModules.home-manager
        (
          let
            pkgs = import nixpkgs { inherit system; };
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
