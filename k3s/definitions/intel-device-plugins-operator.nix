{ lib, ... }:
{
  applications.intel-device-plugins-operator = {
    namespace = "intel-device-plugins-operator";
    createNamespace = true;
    helm.releases.intel-device-plugins-operator = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://intel.github.io/helm-charts";
        chart = "intel-device-plugins-operator";
        version = "0.35.0";
        chartHash = "sha256-yMTzhYE5mojPOHb6292885yuiRGMqEycjVkOuSzRjFI=";
      };
    };
  };
}
