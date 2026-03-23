{ lib, ... }:
{
  applications.intel-gpu-device-plugin = {
    namespace = "intel-gpu-device-plugin";
    createNamespace = true;
    helm.releases.intel-gpu-device-plugin = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://intel.github.io/helm-charts";
        chart = "intel-device-plugins-gpu";
        version = "0.35.0";
        chartHash = "sha256-7OIBGpdWJEpVUUdjBz3ycZGeZNzXX9bw7GyNuuiB/ow=";
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
