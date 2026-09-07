{ ... }:
{
  applications.wled-gradients = {
    namespace = "wled-gradients";
    createNamespace = true;

    resources = {
      configMaps.wled-gradients-config.data = {
        HOST = "0.0.0.0";
        PORT = "3000";
        DATABASE_URL = "sqlite:///data/wled-sunrise.db";
        RUST_LOG = "info";
      };

      persistentVolumeClaims.wled-gradients-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "longhorn";
        resources.requests.storage = "256Mi";
      };

      deployments.wled-gradients.spec = {
        replicas = 1;
        # SQLite file + in-process scheduler are single-instance by design: a
        # rolling update would briefly run two pods against the same
        # ReadWriteOnce PVC and double-fire schedules. Recreate stops the old
        # pod before starting the new one instead.
        strategy.type = "Recreate";
        selector.matchLabels.app = "wled-gradients";
        template = {
          metadata.labels.app = "wled-gradients";
          spec = {
            containers.wled-gradients = {
              image = "forgejo.doma.lol/miro/wled-gradients:latest";
              ports.http.containerPort = 3000;
              envFrom = [
                { configMapRef.name = "wled-gradients-config"; }
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
              ];
              readinessProbe = {
                httpGet = {
                  path = "/";
                  port = 3000;
                };
                initialDelaySeconds = 2;
                periodSeconds = 10;
              };
              livenessProbe = {
                httpGet = {
                  path = "/";
                  port = 3000;
                };
                initialDelaySeconds = 5;
                periodSeconds = 30;
              };
            };
            volumes.data.persistentVolumeClaim.claimName = "wled-gradients-data";
          };
        };
      };

      services.wled-gradients.spec = {
        type = "ClusterIP";
        selector.app = "wled-gradients";
        ports.http = {
          port = 80;
          targetPort = 3000;
        };
      };

      ingressRoutes.wled-gradients.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`wled-gradients.doma.lol`)";
            kind = "Rule";
            services.wled-gradients.port = 80;
          }
        ];
      };

      ingresses.wled-gradients.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "wled-gradients.doma.lol";
          }
        ];
      };

      services.wled-gradients-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "wled-gradients.doma.lol";
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
