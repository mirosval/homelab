{ lib, ... }:
{
  applications.intel-gpu-device-plugin = {
    namespace = "intel-gpu-device-plugin";
    createNamespace = true;
    helm.releases.intel-gpu-device-plugin = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://intel.github.io/helm-charts";
        chart = "intel-device-plugins-gpu";
        version = "0.36.0";
        chartHash = "sha256-vy3XsSzrgDwQXapfFMS+TwYNq2qL8X4DE031LQ8SaWA=";
      };

      values = {
        name = "igpu";
        sharedDevNum = 5;
        nodeFeatureRule = false;
        nodeSelector."intel.feature.node.kubernetes.io/gpu" = "true";
      };
    };
  };
}
