{ ... }:
{
  applications.dashy = {
    namespace = "dashy";
    createNamespace = true;
    resources = {
      deployments.dashy.spec = {
        replicas = 1;
        selector.matchLabels.app = "dashy";

        template = {
          metadata.labels.app = "dashy";

          spec = {
            containers.dashy = {
              image = "lissy93/dashy@sha256:4942e50304530fb449176c3d45bd51b8b4e00bcedb6f8d369c9dda17611c6a81";
              ports.http.containerPort = 8080;
              env = {
                NODE_ENV.value = "production";
              };
              volumeMounts = {
                config = {
                  name = "dashy-config";
                  mountPath = "/app/user-data/conf.yml";
                  subPath = "conf.yml";
                  readOnly = true;
                };
              };
            };
            volumes.config.configMap.name = "dashy-config";
          };
        };
      };

      services.dashy.spec = {
        type = "ClusterIP";
        selector.app = "dashy";

        ports.http = {
          port = 80;
          targetPort = 8080;
        };
      };

      configMaps.dashy-config.data = {
        "conf.yml" = ''
          pageInfo:
            title: Homelab Dashboard
            description: Welcome to your homelab
            logo: https://i.ibb.co/qWWpD0v/astro-dab-128.png

          appConfig:
            theme: dark
            layout: auto
            iconSize: medium
            language: en

          sections:
            - name: Home
              icon: fas fa-home
              items:
                - title: Example Service
                  description: Add your services here
                  icon: fas fa-server
                  url: https://example.com
        '';
      };

      ingressRoutes.dashy.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`dashy.doma.lol`)";
            kind = "Rule";
            services.dashy.port = 80;
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

      ingresses.dashy.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "dashy.doma.lol";
          }
        ];
      };
    };
  };
}
