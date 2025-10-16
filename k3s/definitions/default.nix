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
    ./coredns-config.nix
    ./csi-driver-smb.nix
    ./dashy.nix
    ./dazzle.nix
    ./externaldns.nix
    ./flannel.nix
    ./forgejo.nix
    ./homeassistant.nix
    ./hyperdx.nix
    ./immich.nix
    ./jellyfin.nix
    ./longhorn.nix
    ./metallb.nix
    ./pihole.nix
    ./renovate.nix
    ./sealedsecrets.nix
    ./tailscale.nix
    ./traefik.nix
  ];

}
