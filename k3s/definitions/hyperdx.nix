{ lib, ... }:
{
  applications.hyperdx = {
    namespace = "hyperdx";
    createNamespace = true;
    helm.releases.hyperdx = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://hyperdxio.github.io/helm-charts";
        chart = "hdx-oss-v2";
        version = "0.7.3";
        chartHash = "sha256-TqKX+VIy8aS9euK1gE72pqmXikdnmIuGKngUclzXehE";
      };
      values = {
        hyperdx.frontendUrl = "https://hyperdx.doma.lol";
      };
    };

    resources = {
      ingressRoutes.hyperdx.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`hyperdx.doma.lol`)";
            kind = "Rule";
            services.hyperdx-hdx-oss-v2-app.port = 3000;
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

      ingresses.hyperdx.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "hyperdx.doma.lol";
          }
        ];
      };
    };
  };
}
