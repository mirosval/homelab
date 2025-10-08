{ lib, ... }:
{
  applications.forgejo = {
    namespace = "forgejo";
    createNamespace = true;
    helm.releases.forgejo = {
      chart = lib.helm.downloadHelmChart {
        repo = "oci://code.forgejo.org/forgejo-helm";
        chart = "forgejo";
        version = "14.0.4";
        chartHash = "sha256-j2Wd9b6ds9QayKYPjxqlKBXZvmuQd3F6l/68PzBCkFY=";
      };

      values = {
        global = {
          storageClass = "longhorn";
          hostnames = [ "forgejo.doma.lol" ];
        };
        gitea = {
          admin.existingSecret = "forgejo";
          config.server = {
            DOMAIN = "forgejo.doma.lol";
            ROOT_URL = "https://forgejo.doma.lol";
          };
        };
      };
    };

    resources = {
      ingressRoutes.forgejo.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`forgejo.doma.lol`)";
            kind = "Rule";
            services.forgejo-http.port = 3000;
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

      ingresses.forgejo.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "forgejo.doma.lol";
          }
        ];
      };
    };
  };
}
