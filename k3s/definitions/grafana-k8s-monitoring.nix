{ lib, ... }:
{
  applications.grafana-k8s-monitoring = {
    namespace = "grafana";
    createNamespace = true;
    helm.releases.grafana-k8s-monitoring = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://grafana.github.io/helm-charts";
        chart = "k8s-monitoring";
        version = "3.5.5";
        chartHash = "sha256-aSoFsFYWKS7WIfo7ltDVIsJq30DjtePZMpnwQTTIy5k=";
      };

      values = {
        cluster.name = "homelab";

        destinations = [
          {
            name = "localPrometheus";
            type = "prometheus";
            url = "http://prometheus.monitoring.svc.cluster.local:9090";
          }
        ];

        clusterMetrics.enabled = true;
        # podLogs.enabled = true;

        alloy-metrics.enabled = true;
        # alloy-logs.enabled = true;
      };
    };
  };
}
