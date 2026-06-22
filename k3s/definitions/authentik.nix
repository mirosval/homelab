{ lib, ... }:
{
  applications.authentik = {
    namespace = "authentik";
    createNamespace = true;

    helm.releases.authentik = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.goauthentik.io";
        chart = "authentik";
        version = "2026.2.2";
        chartHash = "sha256-syF37Tymrvvfx5srWj0nRkTB5Us/qwvvVW6kHrHtRi0=";
      };

      values = {
        authentik.existingSecret.secretName = "authentik";
        postgresql.enabled = false;
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
            services.authentik-server.port = 80;
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
