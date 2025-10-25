{ lib, ... }:
{
  applications.intel-gpu-device-plugin = {
    namespace = "intel-gpu-device-plugin";
    createNamespace = true;
    helm.releases.intel-gpu-device-plugin = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://intel.github.io/helm-charts";
        chart = "intel-device-plugins-gpu";
        version = "0.34.0";
        chartHash = "sha256-gqvn0sZvbfc3i6t8fSBMblC4mPsW/KCCNnj/gnOVRYs=";
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
