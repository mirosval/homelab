{ lib, ... }:
{
  applications.cilium = {
    namespace = "kube-system";
    createNamespace = false;
    helm.releases.cilium = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://helm.cilium.io";
        chart = "cilium";
        version = "v1.18.2";
        chartHash = "sha256-V6v+786h++de7dLTZfP7EmTD6MMkUlZTNEAiOX8x8us=";
      };

      values = {
      };
    };
  };
}
