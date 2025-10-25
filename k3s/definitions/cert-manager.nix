{ lib, ... }:
{
  applications.cert-manager = {
    namespace = "cert-manager";
    createNamespace = true;
    helm.releases.cert-manager = {
      chart = lib.helm.downloadHelmChart {
        repo = "oci://quay.io/jetstack/charts";
        chart = "cert-manager";
        version = "v1.19.1";
        chartHash = "sha256-fs14wuKK+blC0l+pRfa//oBV2X+Dr3nNX+Z94nrQVrA=";
      };

      values = {
      };
    };

    resources = {
      issuers
    };
  };
}
