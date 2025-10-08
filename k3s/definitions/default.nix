{
  nixidy.target.repository = "https://github.com/mirosval/homelab.git";
  nixidy.target.branch = "main";
  nixidy.target.rootPath = "./k3s/generated_manifests";
  nixidy.applicationImports = [
    ../../lib/generated/metallb.nix
    ../../lib/generated/traefik.nix
    ../../lib/generated/cnpg.nix
  ];
  imports = [
    ./argocd.nix
    ./cloudnativepg.nix
    ./csi-driver-smb.nix
    ./dashy.nix
    ./externaldns.nix
    ./forgejo.nix
    ./homeassistant.nix
    ./immich.nix
    ./jellyfin.nix
    ./longhorn.nix
    ./metallb.nix
    ./pihole.nix
    ./sealedsecrets.nix
    ./tailscale.nix
    ./traefik.nix
  ];

}
