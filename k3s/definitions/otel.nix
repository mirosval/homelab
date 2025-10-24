{ lib, ... }:
{

  applications.otel = {
    namespace = "otel";
    createNamespace = true;
    helm.releases.otel-daemonset = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://open-telemetry.github.io/opentelemetry-helm-charts";
        chart = "opentelemetry-collector";
        version = "0.138.0";
        chartHash = "sha256-fAOaF22N7Skw2xD5s1XYqdOcF+7WmFImG1GJGoNcR6c=";
      };
      values = {
        mode = "daemonset";

        image = {
          repository = "otel/opentelemetry-collector-contrib";
          tag = "0.138.0";
        };

        clusterRole = {
          create = true;
          rules = [
            {
              apiGroups = [ "" ];
              resources = [ "nodes/proxy" ];
              verbs = [ "get" ];
            }
          ];
        };

        presets = {
          logsCollection.enabled = true;
          hostMetrics.enabled = true;
          kubernetesAttributes = {
            enabled = true;
            extractAllPodLabels = true;
            extractAllPodAnnotations = true;
          };
          kubeletMetrics.enabled = true;
        };

        extraEnvs = [
          {
            name = "HYPERDX_API_KEY";
            valueFrom = {
              secretKeyRef = {
                name = "hyperdx-ingestion";
                key = "HYPERDX_API_KEY";
                optional = true;
              };
            };
          }
          {
            name = "YOUR_OTEL_COLLECTOR_ENDPOINT";
            value = "http://hyperdx-hdx-oss-v2-otel-collector.hyperdx.svc.cluster.local:4318";
          }
        ];

        config = {
          receivers = {
            kubeletstats = {
              collection_interval = "20s";
              auth_type = "serviceAccount";
              endpoint = "\${env:K8S_NODE_NAME}:10250";
              insecure_skip_verify = true;
              metrics = {
                "k8s.pod.cpu_limit_utilization".enabled = true;
                "k8s.pod.cpu_request_utilization".enabled = true;
                "k8s.pod.memory_limit_utilization".enabled = true;
                "k8s.pod.memory_request_utilization".enabled = true;
                "k8s.pod.uptime".enabled = true;
                "k8s.node.uptime".enabled = true;
                "k8s.container.cpu_limit_utilization".enabled = true;
                "k8s.container.cpu_request_utilization".enabled = true;
                "k8s.container.memory_limit_utilization".enabled = true;
                "k8s.container.memory_request_utilization".enabled = true;
                "container.uptime".enabled = true;
              };
            };
          };
          exporters = {
            otlphttp = {
              endpoint = "http://hyperdx-hdx-oss-v2-otel-collector.hyperdx.svc.cluster.local:4318";
              compression = "gzip";
              headers = {
                authorization = "\${env:HYPERDX_API_KEY}";
              };
            };
          };

          service = {
            pipelines = {
              logs = {
                exporters = [ "otlphttp" ];
              };
              metrics = {
                exporters = [ "otlphttp" ];
              };
            };
          };
        };
      };
    };

    helm.releases.otel-deployment = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://open-telemetry.github.io/opentelemetry-helm-charts";
        chart = "opentelemetry-collector";
        version = "0.138.0";
        chartHash = "sha256-fAOaF22N7Skw2xD5s1XYqdOcF+7WmFImG1GJGoNcR6c=";
      };
      values = {
        mode = "deployment";

        image = {
          repository = "otel/opentelemetry-collector-contrib";
          tag = "0.138.0";
        };

        # We only want one of these collectors - any more and we'd produce duplicate data
        replicaCount = 1;

        presets = {
          kubernetesAttributes = {
            enabled = true;
            extractAllPodLabels = true;
            extractAllPodAnnotations = true;
          };

          kubernetesEvents = {
            enabled = true;
          };

          clusterMetrics = {
            enabled = true;
          };
        };

        extraEnvs = [
          {
            name = "HYPERDX_API_KEY";
            valueFrom = {
              secretKeyRef = {
                name = "hyperdx-ingestion";
                key = "HYPERDX_API_KEY";
                optional = true;
              };
            };
          }
          {
            name = "YOUR_OTEL_COLLECTOR_ENDPOINT";
            value = "http://hyperdx-hdx-oss-v2-otel-collector.hyperdx.svc.cluster.local:4318";
          }
        ];

        config = {
          exporters = {
            otlphttp = {
              endpoint = "http://hyperdx-hdx-oss-v2-otel-collector.hyperdx.svc.cluster.local:4318";
              compression = "gzip";
              headers = {
                authorization = "\${env:HYPERDX_API_KEY}";
              };
            };
          };

          service = {
            pipelines = {
              logs = {
                exporters = [ "otlphttp" ];
              };
              metrics = {
                exporters = [ "otlphttp" ];
              };
            };
          };
        };
      };
    };
  };
}
