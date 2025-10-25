{ lib, ... }:
{
  applications.intel-device-plugins-operator = {
    namespace = "intel-device-plugins-operator";
    createNamespace = true;
    helm.releases.intel-device-plugins-operator = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://intel.github.io/helm-charts";
        chart = "intel-device-plugins-operator";
        version = "0.34.0";
        chartHash = "sha256-5K3Gzzg+V7CFPCck3eh6E80Lnn3F3PwIWog5B+eNHgI=";
      };
    };
  };
}
