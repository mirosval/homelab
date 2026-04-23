{ ... }:
{
  applications.element = {
    namespace = "element";
    createNamespace = true;

    resources = {
      configMaps.element-config.data = {
        "config.json" = builtins.toJSON {
          default_server_config = {
            "m.homeserver" = {
              base_url = "https://matrix.doma.lol";
              server_name = "doma.lol";
            };
          };
          disable_custom_urls = true;
          disable_guests = true;
          brand = "Element";
          default_theme = "dark";
          room_directory.servers = [ "doma.lol" ];
        };
      };

      deployments.element.spec = {
        replicas = 1;
        selector.matchLabels.app = "element";
        template = {
          metadata.labels.app = "element";
          spec = {
            containers.element = {
              image = "vectorim/element-web:v1.12.15";
              ports.http.containerPort = 80;
              volumeMounts = [
                {
                  name = "config";
                  mountPath = "/app/config.json";
                  subPath = "config.json";
                  readOnly = true;
                }
              ];
              resources = {
                requests = {
                  cpu = "10m";
                  memory = "32Mi";
                };
                limits = {
                  cpu = "200m";
                  memory = "128Mi";
                };
              };
            };
            volumes.config.configMap.name = "element-config";
          };
        };
      };

      services.element.spec = {
        type = "ClusterIP";
        selector.app = "element";
        ports.http = {
          port = 80;
          targetPort = 80;
        };
      };

      middlewares.element-security-headers.spec.headers.customResponseHeaders = {
        X-Frame-Options = "SAMEORIGIN";
        X-Content-Type-Options = "nosniff";
        X-XSS-Protection = "1; mode=block";
        Content-Security-Policy = "frame-ancestors 'self'";
      };

      ingressRoutes.element.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`element.doma.lol`)";
            kind = "Rule";
            middlewares = [ { name = "element-security-headers"; } ];
            services.element.port = 80;
          }
        ];
      };

      ingresses.element.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "element.doma.lol";
          }
        ];
      };

      services.element-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "element.doma.lol";
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
