{ lib, ... }:
{
  applications.grafana = {
    namespace = "grafana";
    createNamespace = true;
    helm.releases.grafana = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://grafana.github.io/helm-charts";
        chart = "grafana";
        version = "10.1.2";
        chartHash = "sha256-tDlAzBBj95svRRjTsLzyGDfvw4r1kakuHU7CzUg68QU=";
      };

      values = {
        persistence = {
          enabled = true;
          storageClassName = "longhorn";
        };
      };
    };

    resources = {
      ingressRoutes.grafana.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`grafana.doma.lol`)";
            kind = "Rule";
            services.grafana-web.port = 80;
          }
        ];
      };

      ingresses.grafana.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "grafana.doma.lol";
          }
        ];
      };
    };
  };
}
