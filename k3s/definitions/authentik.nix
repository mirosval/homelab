{ lib, ... }:
{
  applications.authentik = {
    namespace = "authentik";
    createNamespace = true;

    helm.releases.authentik = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.goauthentik.io";
        chart = "authentik";
        version = "2026.2.1";
        chartHash = "sha256-7x3H//RHMpEeXS86TmOHt0ZHfCLTQpHSnEcIi2zuTFE=";
      };

      values = {
        authentik.existingSecret.secretName = "authentik";
        postgresql.enabled = false;
        server.ingress = {
          enabled = true;
          hosts = [
            "authentik.doma.lol"
          ];
        };
      };
    };

    resources = {
      clusters.authentik-database.spec = {
        instances = 1;
        storage = {
          size = "1Gi";
          storageClass = "longhorn";
        };
      };

      ingressRoutes.authentik.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`authentik.doma.lol`)";
            kind = "Rule";
            services.authentik-server.port = 9000;
          }
        ];
      };

      ingresses.authentik.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "authentik.doma.lol";
          }
        ];
      };
    };
  };
}
