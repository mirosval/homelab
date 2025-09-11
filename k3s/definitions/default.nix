{
  nixidy.target.repository = "https://github.com/mirosval/homelab.git";
  nixidy.target.branch = "master";
  nixidy.target.rootPath = "./k3s/generated_manifests";
  imports = [
    ./argocd.nix
    ./homeassistant.nix
    ./longhorn.nix
    ./metallb.nix
  ];
}
