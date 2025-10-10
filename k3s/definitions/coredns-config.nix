{ ... }:
{
  applications.coredns-config = {
    namespace = "kube-system";
    createNamespace = false;
    resources.configMaps.coredns-doma-lol.data = {
      "rewritedomalol.override" = "rewrite name suffix .doma.lol traefik.traefik.svc.cluster.local.";
    };
  };
}
