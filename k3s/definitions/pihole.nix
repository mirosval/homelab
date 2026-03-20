{ lib, ... }:
let
  piholeChart = lib.helm.downloadHelmChart {
    repo = "https://mojo2600.github.io/pihole-kubernetes/";
    chart = "pihole";
    version = "2.35.0";
    chartHash = "sha256-wWFj3/2BsiQMXcAoG8buJRWUXkcKS6Ies1veUtMcHYc=";
  };
in
{
  applications.pihole = {
    namespace = "pihole";
    createNamespace = true;
    helm.releases.pihole = {
      chart = piholeChart;

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

  applications.pihole-tailscale = {
    namespace = "pihole-tailscale";
    createNamespace = true;
    helm.releases.pihole-tailscale = {
      chart = piholeChart;

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
          loadBalancerClass = "tailscale";
          type = "LoadBalancer";
        };

        admin.existingSecret = "pihole-tailscale-password";
      };
    };

    resources = {
      ingressRoutes.pihole-tailscale.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`pihole.doma.lol`)";
            kind = "Rule";
            services.pihole-tailscale-web.port = 80;
          }
        ];
      };

      ingresses.pihole-tailscale.spec = {
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
