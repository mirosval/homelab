{ ... }:
{
  applications.coredns-config = {
    namespace = "kube-system";
    createNamespace = false;
    resources.configMaps.coredns-custom.data = {
      "rewritedomalol.override" =
        "rewrite name rewrite (.*)\.doma\.lol traefik.traefik.svc.cluster.local.";
    };
  };
}
