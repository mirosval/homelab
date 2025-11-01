{
  nixidy.target.repository = "https://github.com/mirosval/homelab.git";
  nixidy.target.branch = "main";
  nixidy.target.rootPath = "./k3s/generated_manifests";
  nixidy.applicationImports = [
    ../../lib/generated/metallb.nix
    ../../lib/generated/traefik.nix
    ../../lib/generated/cnpg.nix
    ../../lib/generated/cert-manager.nix
  ];
  imports = [
    ./argocd.nix
    ./cert-manager.nix
    ./cloudnativepg.nix
    ./coredns-config.nix
    ./csi-driver-smb.nix
    ./dashy.nix
    ./dazzle.nix
    ./externaldns.nix
    ./forgejo.nix
    ./grafana-k8s-monitoring.nix
    ./grafana-loki.nix
    ./grafana.nix
    ./homeassistant.nix
    ./hyperdx.nix
    ./immich.nix
    ./intel-device-plugins-operator.nix
    ./intel-gpu-device-plugin.nix
    ./jellyfin.nix
    ./longhorn.nix
    ./metallb.nix
    ./otel.nix
    ./pihole.nix
    ./prometheus.nix
    ./renovate.nix
    ./sealedsecrets.nix
    ./tailscale.nix
    ./traefik.nix
  ];

}
