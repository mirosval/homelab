{ ... }:
{
  applications.tinyauth = {
    namespace = "tinyauth";
    createNamespace = true;
    resources = {

      deployments.tinyauth.spec = {
        replicas = 1;
        selector.matchLabels.app = "tinyauth";

        template = {
          metadata.labels.app = "tinyauth";

          spec = {
            containers.tinyauth = {
              image = "ghcr.io/steveiliop56/tinyauth:v5";
              ports.http.containerPort = 3000;
              env = {
                TINYAUTH_APP_URL.value = "https://tinyauth.doma.lol";
                TINYAUTH_SECRET.valueFrom.secretKeyRef = {
                  name = "tinyauth-secret";
                  key = "secret";
                };
                TINYAUTH_AUTH_USERS_FILE.value = "/run/tinyauth/users";
              };
              volumeMounts = [
                {
                  name = "users";
                  mountPath = "/run/tinyauth";
                  readOnly = true;
                }
              ];
            };
            volumes.users.secret = {
              secretName = "tinyauth-secret";
              items = [
                {
                  key = "users";
                  path = "users";
                }
              ];
            };
          };
        };
      };

      services.tinyauth.spec = {
        type = "ClusterIP";
        selector.app = "tinyauth";
        ports.http = {
          port = 80;
          targetPort = 3000;
        };
      };

      ingressRoutes.tinyauth.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`tinyauth.doma.lol`)";
            kind = "Rule";
            services.tinyauth.port = 80;
          }
        ];
      };

      ingresses.tinyauth.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "tinyauth.doma.lol";
          }
        ];
      };

      services.tinyauth-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "tinyauth.doma.lol";
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
