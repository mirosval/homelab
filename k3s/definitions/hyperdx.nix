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
      values = { };
    };
  };
}
