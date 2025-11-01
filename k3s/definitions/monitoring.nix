{ lib, ... }:
{
  applications.monitoring = {
    namespace = "monitoring";
    createNamespace = true;

    helm.releases.grafana = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://grafana.github.io/helm-charts";
        chart = "grafana";
        version = "10.1.2";
        chartHash = "sha256-tDlAzBBj95svRRjTsLzyGDfvw4r1kakuHU7CzUg68QU=";
      };

      values = {
        persistence = {
          enabled = true;
          storageClassName = "longhorn";
        };
      };
    };

    helm.releases.k8s-monitoring = {
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
            url = "http://prometheus-server/api/v1/write";
          }
          {
            name = "loki";
            type = "loki";
            url = "http://grafana-loki-gateway/loki/api/v1/push";
          }
        ];

        podLogs.enabled = true;
        alloy-logs.enabled = true;
        # user prometheus
        clusterMetrics.enabled = false;
        alloy-metrics.enabled = false;
      };
    };

    helm.releases.loki = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://grafana.github.io/helm-charts";
        chart = "loki";
        version = "6.44.0";
        chartHash = "sha256-NMn2+CUYWbYKixp1mBSEp4cbB8RCqrE657UOP8tXRFE=";
      };

      values = {
        loki = {
          auth_enabled = false;
          commonConfig.replication_factor = 1;

          schemaConfig.configs = [
            {
              from = "2024-04-01";
              store = "tsdb";
              object_store = "s3";
              schema = "v13";
              index = {
                prefix = "loki_index_";
                period = "24h";
              };
            }
          ];

          pattern_ingester.enabled = true;

          limits_config = {
            allow_structured_metadata = true;
            volume_enabled = true;
          };

          ruler.enable_api = true;
        };

        minio.enabled = true;

        deploymentMode = "SingleBinary";

        singleBinary.replicas = 1;

        # Zero out replica counts of other deployment modes
        backend.replicas = 0;
        read.replicas = 0;
        write.replicas = 0;
        ingester.replicas = 0;
        querier.replicas = 0;
        queryFrontend.replicas = 0;
        queryScheduler.replicas = 0;
        distributor.replicas = 0;
        compactor.replicas = 0;
        indexGateway.replicas = 0;
        bloomCompactor.replicas = 0;
        bloomGateway.replicas = 0;
      };
    };

    helm.releases.prometheus = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://prometheus-community.github.io/helm-charts";
        chart = "prometheus";
        version = "27.42.0";
        chartHash = "sha256-nZkJzqnY4ynAtmccQtn1gb1F41SItwDdh3ipHA4PnNU=";
      };

      values = {
        server.persistentVolume.storageClass = "longhorn";
        kube-state-metrics.enabled = true;
        prometheus-node-exporter.enabled = true;
        prometheus-pushgateway.enabled = true;
      };
    };

    resources = {
      ingressRoutes.grafana.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`grafana.doma.lol`)";
            kind = "Rule";
            services.grafana.port = 80;
          }
        ];
      };

      ingresses.grafana.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "grafana.doma.lol";
          }
        ];
      };
    };
  };
}
