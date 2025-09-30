{ lib, ... }:
{
  applications.pihole = {
    namespace = "pihole";
    createNamespace = true;
    helm.releases.pihole = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://mojo2600.github.io/pihole-kubernetes/";
        chart = "pihole";
        version = "v2.34.0";
        chartHash = "sha256-nhvifpDdM8MoxF43cJAi6o+il2BbHX+udVAvvm1PukM=";
      };

      values = {
        replicaCount = 1;

        DNS1 = "10.42.0.1";

        persistentVolumeClaim = {
          enabled = true;
          storageClass = "longhorn";
        };

        serviceWeb = {
          type = "ClusterIP";
        };

        serviceDns = {
          loadBalancerIP = "10.42.1.250";
          annotations = {
            "metallb.universe.tf/address-pool" = "pool";
            "metallb.universe.tf/allow-shared-ip" = "pihole-svc";
          };
          type = "LoadBalancer";
        };

        admin.existingSecret = "pihole-password";
      };
    };

    resources = {
      ingressRoutes.pihole.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`pihole.doma.lol`)";
            kind = "Rule";
            services.pihole-web.port = 80;
          }
        ];
        tls = {
          certResolver = "letsencrypt";
          domains = [
            {
              main = "doma.lol";
              sans = [ "*.doma.lol" ];
            }
          ];
        };
      };

      ingresses.pihole.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "pihole.doma.lol";
          }
        ];
      };
    };
  };
}
