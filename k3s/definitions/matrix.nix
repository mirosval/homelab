{ ... }:
{
  applications.matrix = {
    namespace = "matrix";
    createNamespace = true;

    resources = {
      persistentVolumeClaims.matrix-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "longhorn";
        resources.requests.storage = "10Gi";
      };

      configMaps.matrix-config.data = {
        "conduwuity.toml" = ''
          [global]
          server_name = "doma.lol"
          database_path = "/data/rocksdb"
          address = "0.0.0.0"
          port = 6167
          allow_registration = false
          log = "warn,state_res=warn"
          trusted_servers = ["matrix.org"]
        '';
      };

      deployments.matrix.spec = {
        replicas = 1;
        selector.matchLabels.app = "matrix";
        template = {
          metadata.labels.app = "matrix";
          spec = {
            containers.matrix = {
              image = "ghcr.io/continuwuity/continuwuity:v0.5.5";
              ports.http.containerPort = 6167;
              args = [
                "--config"
                "/etc/conduwuity/conduwuity.toml"
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
                {
                  name = "config";
                  mountPath = "/etc/conduwuity";
                  readOnly = true;
                }
              ];
              resources = {
                requests = {
                  cpu = "100m";
                  memory = "256Mi";
                };
                limits = {
                  cpu = "1";
                  memory = "1Gi";
                };
              };
            };
            volumes = {
              data.persistentVolumeClaim.claimName = "matrix-data";
              config.configMap.name = "matrix-config";
            };
          };
        };
      };

      services.matrix.spec = {
        type = "ClusterIP";
        selector.app = "matrix";
        ports.http = {
          port = 80;
          targetPort = 6167;
        };
      };

      # Matrix client/server API
      ingressRoutes.matrix.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`matrix.doma.lol`)";
            kind = "Rule";
            services.matrix.port = 80;
          }
        ];
      };

      # Well-known delegation: server_name is doma.lol, actual server at matrix.doma.lol
      # conduwuity natively serves /.well-known/matrix/* endpoints
      ingressRoutes.matrix-well-known.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`doma.lol`) && PathPrefix(`/.well-known/matrix`)";
            kind = "Rule";
            services.matrix.port = 80;
          }
        ];
      };

      ingresses.matrix.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "matrix.doma.lol";
          }
        ];
      };

      services.matrix-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "matrix.doma.lol";
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
