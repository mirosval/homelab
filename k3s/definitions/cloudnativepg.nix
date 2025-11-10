{ lib, ... }:
{
  applications.cloudnativepg = {
    namespace = "cnpg-system";
    createNamespace = true;
    helm.releases.cloudnativepg = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://cloudnative-pg.github.io/charts";
        chart = "cloudnative-pg";
        version = "0.26.1";
        chartHash = "sha256-8VgcvZqJS/jts2TJJjaj6V4BRDy56phyd0gwPs0bhnI=";
      };
    };
  };
}

