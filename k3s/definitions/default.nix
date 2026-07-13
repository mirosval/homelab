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

  # The child Application CRs nixidy generates carry an explicit
  # `syncPolicy: {}` when autoSync is disabled (our default). Argo's API
  # server prunes that empty object from the live object, so the "apps"
  # app-of-apps sees a perpetual diff against git. Argo's Application CRD
  # has `spec.syncPolicy.automated.enabled` specifically to disable
  # automated sync while keeping the object non-empty (avoiding the
  # prune), but nixidy's bundled CRD types don't expose that field yet
  # (only prune/selfHeal/allowEmpty), so we can't set it here. Ignore the
  # syncPolicy field on the resources "apps" manages instead.
  applications.apps.ignoreDifferences.Application = {
    group = "argoproj.io";
    jsonPointers = [ "/spec/syncPolicy" ];
  };
  imports = [
    ./argocd.nix
    ./authentik.nix
    ./cert-manager.nix
    ./cloudnativepg.nix
    ./coredns-config.nix
    ./csi-driver-smb.nix
    ./dashy.nix
    ./dazzle.nix
    ./element.nix
    ./externaldns.nix
    ./forgejo.nix
    ./monitoring.nix
    ./homeassistant.nix
    ./immich.nix
    ./intel-device-plugins-operator.nix
    ./intel-gpu-device-plugin.nix
    ./jellyfin.nix
    ./kata.nix
    ./llama.nix
    ./longhorn.nix
    ./matrix.nix
    ./matter-server.nix
    ./metallb.nix
    ./moltis.nix
    ./otbr.nix
    ./pihole.nix
    ./renovate.nix
    ./sealedsecrets.nix
    ./tailscale.nix
    ./tinyauth.nix
    ./traefik.nix
    ./vaultwarden.nix
  ];

}
