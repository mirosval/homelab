{ lib, ... }:
{
  applications.sealed-secrets = {
    namespace = "sealed-secrets";
    createNamespace = true;
    helm.releases.sealed-secrets = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://bitnami.github.io/sealed-secrets";
        chart = "sealed-secrets";
        version = "2.19.0";
        chartHash = "sha256-mQD+h6EQSddBGMFpBos62OeUCGWXnCUFG9F8hW98VQI=";
      };
    };
  };
}
