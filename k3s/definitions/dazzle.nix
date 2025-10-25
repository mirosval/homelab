{ ... }:
{
  applications.dazzle = {
    namespace = "dazzle";
    createNamespace = true;
    resources = {
      deployments.dazzle.spec = {
        replicas = 1;
        selector.matchLabels.app = "dazzle";
        template = {
          metadata.labels.app = "dazzle";
          spec = {
            containers.dashy = {
              image = "forgejo.doma.lol/miro/dazzle:latest";
              ports.http.containerPort = 3000;
            };
          };
        };
      };

      services.dazzle.spec = {
        type = "ClusterIP";
        selector.app = "dazzle";
        ports.http = {
          port = 80;
          targetPort = 3000;
        };
      };

      ingressRoutes.dazzle.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`dazzle.doma.lol`)";
            kind = "Rule";
            services.dazzle.port = 80;
          }
        ];
      };

      ingresses.dazzle.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "dazzle.doma.lol";
          }
        ];
      };
    };
  };
}
