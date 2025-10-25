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
        global.storageClassName = "longhorn";
        hyperdx.frontendUrl = "https://hyperdx.doma.lol";
      };
    };

    resources = {
      configMaps.otel-config-vars = { };
      ingressRoutes.hyperdx.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`hyperdx.doma.lol`)";
            kind = "Rule";
            services.hyperdx-hdx-oss-v2-app.port = 3000;
          }
        ];
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
