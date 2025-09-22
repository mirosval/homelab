{ lib, ... }:
{
  applications.traefik = {
    namespace = "traefik";
    createNamespace = true;
    helm.releases.traefik = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://traefik.github.io/charts";
        chart = "traefik";
        version = "v37.1.1";
        chartHash = "sha256-h7jpw/wS9+XU7mIFn7T/sgZQPvH+XK4wHOFzy3TdFYg=";
      };
      values = {

      };
    };
  };
}
