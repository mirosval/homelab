{
  nixidy.target.repository = "https://github.com/mirosval/homelab.git";
  nixidy.target.branch = "master";
  nixidy.target.rootPath = "./k3s/generated_manifests";
  nixidy.applicationImports = [
    ../../lib/generated/metallb.nix
    ../../lib/generated/traefik.nix
  ];
  imports = [
    ./argocd.nix
    ./externaldns.nix
    ./homeassistant.nix
    ./longhorn.nix
    ./metallb.nix
    ./pihole.nix
    ./sealedsecrets.nix
    ./tailscale.nix
    ./traefik.nix
  ];

}
