{ lib, ... }:
{
  applications.jellyfin = {
    namespace = "jellyfin";
    createNamespace = true;
    helm.releases.jellyfin = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://jellyfin.github.io/jellyfin-helm";
        chart = "jellyfin";
        version = "2.3.0";
        chartHash = "sha256-uqdSUZ034DXIGsEyJEh7XXmy+Ru6ovrhw8SOf4ZqKBQ=";
      };

      values = {

        persistence = {
          config = {
            storageClass = "longhorn";
          };
          media = {
            accessMode = "ReadOnly";
            existingClaim = "pvc-movies-ro";
          };
        };
      };
    };

    resources = {
      ingressRoutes.jellyfin.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`jellyfin.doma.lol`)";
            kind = "Rule";
            services.jellyfin.port = 8096;
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

      ingresses.pihole.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "pihole.doma.lol";
          }
        ];
      };
    };
  };
}
