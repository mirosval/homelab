{ ... }:
{
  applications.vaultwarden = {
    namespace = "vaultwarden";
    createNamespace = true;

    resources = {
      clusters.vaultwarden-database.spec = {
        instances = 1;
        storage = {
          size = "1Gi";
          storageClass = "longhorn";
        };
      };

      persistentVolumeClaims.vaultwarden-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "longhorn";
        resources.requests.storage = "1Gi";
      };

      deployments.vaultwarden.spec = {
        replicas = 1;
        selector.matchLabels.app = "vaultwarden";
        template = {
          metadata.labels.app = "vaultwarden";
          spec = {
            containers.vaultwarden = {
              image = "vaultwarden/server:1.35.6";
              ports.http.containerPort = 80;
              env = {
                DATABASE_URL.valueFrom.secretKeyRef = {
                  name = "vaultwarden-database-app";
                  key = "uri";
                };
                ADMIN_TOKEN.valueFrom.secretKeyRef = {
                  name = "vaultwarden";
                  key = "ADMIN_TOKEN";
                };
              };
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
              ];
            };
            volumes.data.persistentVolumeClaim.claimName = "vaultwarden-data";
          };
        };
      };

      services.vaultwarden.spec = {
        type = "ClusterIP";
        selector.app = "vaultwarden";
        ports.http = {
          port = 80;
          targetPort = 80;
        };
      };

      ingressRoutes.vaultwarden.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`vaultwarden.doma.lol`)";
            kind = "Rule";
            services.vaultwarden.port = 80;
          }
        ];
      };

      ingresses.vaultwarden.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "vaultwarden.doma.lol";
          }
        ];
      };

      services.vaultwarden-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "vaultwarden.doma.lol";
          "external-dns.alpha.kubernetes.io/target" = "homelab.boreal-scala.ts.net";
        };
        spec = {
          type = "ClusterIP";
          clusterIP = "None";
        };
      };
    };
  };
}
