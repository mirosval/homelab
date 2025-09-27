{ lib, ... }:
{
  applications.external-dns = {
    namespace = "external-dns";
    createNamespace = true;
    helm.releases.external-dns = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://kubernetes-sigs.github.io/external-dns/";
        chart = "external-dns";
        version = "1.19";
        chartHash = "sha256-qzmJ1wtxoFlLZNufoMX5U5U+YKjQSLJXQJRxXY+gRsk=";
      };

      values = {
      };
    };
  };
}
