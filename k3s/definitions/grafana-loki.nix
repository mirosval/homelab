{ lib, ... }:
{
  applications.grafana-loki = {
    namespace = "grafana-loki";
    createNamespace = true;
    helm.releases.grafana-loki = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://grafana.github.io/helm-charts";
        chart = "loki";
        version = "6.44.0";
        chartHash = "sha256-NMn2+CUYWbYKixp1mBSEp4cbB8RCqrE657UOP8tXRFE=";
      };

      values = {
        loki = {
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
  };
}
