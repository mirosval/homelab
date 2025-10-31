{ lib, ... }:
{
  applications.prometheus = {
    namespace = "prometheus";
    createNamespace = true;
    helm.releases.prometheus = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://prometheus-community.github.io/helm-charts";
        chart = "prometheus";
        version = "27.42.0";
        chartHash = "sha256-nZkJzqnY4ynAtmccQtn1gb1F41SItwDdh3ipHA4PnNU=";
      };

      values = {
        server = {
          persistentVolume.storageClass = "longhorn";
          extraArgs = {
            "web.enable-remote-write-receiver" = "null";
          };
        };
        kube-state-metrics.enabled = false;
        prometheus-node-exporter.enabled = false;
        prometheus-pushgateway.enabled = false;
      };
    };
  };
}
