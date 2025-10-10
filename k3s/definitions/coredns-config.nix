{ ... }:
{
  applications.coredns-config = {
    namespace = "kube-system";
    createNamespace = false;
    # This tells coredns to rewrite all dns queries from within the cluster
    # that would have gone to *.doma.lol to go directly to the Traefik instead
    resources.configMaps.coredns-custom.data = {
      "log.override" = "log";
      "doma.lol.server" = ''
        doma.lol:53 {
          log
          rewrite name regex (.*)\.doma\.lol traefik.traefik.svc.cluster.local
          forward . 127.0.0.1
        } 
      '';
    };
  };
}
