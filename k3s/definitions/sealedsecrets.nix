{ lib, ... }:
{
  applications.sealed-secrets = {
    namespace = "sealed-secrets";
    createNamespace = true;
    helm.releases.sealed-secrets = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://bitnami-labs.github.io/sealed-secrets";
        chart = "sealed-secrets";
        version = "2.17.7";
        chartHash = "sha256-w38taCkRKyvPTNrvNhrQc8vjMGSYvL6ugu5VTfxU9og=";
      };
    };
  };
}
