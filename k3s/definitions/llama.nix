{ ... }:
{
  applications.llama = {
    namespace = "llama";
    createNamespace = true;

    resources = {
      persistentVolumeClaims.llama-models.spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "longhorn";
        resources.requests.storage = "5Gi";
      };

      deployments.llama.spec = {
        replicas = 1;
        selector.matchLabels.app = "llama";
        template = {
          metadata.labels.app = "llama";
          spec = {
            initContainers = [
              {
                name = "download-model";
                image = "busybox:1.37.0";
                command = [
                  "sh"
                  "-c"
                  ''
                    test -f /models/gemma-4-E2B-it-IQ4_XS.gguf || \
                      wget -O /models/gemma-4-E2B-it-IQ4_XS.gguf \
                        "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-IQ4_XS.gguf"
                  ''
                ];
                volumeMounts = [
                  {
                    name = "models";
                    mountPath = "/models";
                  }
                ];
              }
            ];
            containers.llama = {
              image = "ghcr.io/ggml-org/llama.cpp:server-intel";
              args = [
                "-m" "/models/gemma-4-E2B-it-IQ4_XS.gguf"
                "--host" "0.0.0.0"
                "--port" "8080"
                "--n-gpu-layers" "99"
              ];
              ports.http.containerPort = 8080;
              resources.limits."gpu.intel.com/i915" = "1000m";
              volumeMounts = [
                {
                  name = "models";
                  mountPath = "/models";
                }
              ];
            };
            volumes.models.persistentVolumeClaim.claimName = "llama-models";
            affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100;
                podAffinityTerm = {
                  labelSelector.matchLabels = {
                    "app.kubernetes.io/instance" = "jellyfin";
                    "app.kubernetes.io/name" = "jellyfin";
                  };
                  namespaces = [ "jellyfin" ];
                  topologyKey = "kubernetes.io/hostname";
                };
              }
              {
                weight = 100;
                podAffinityTerm = {
                  labelSelector.matchLabels = {
                    "app.kubernetes.io/instance" = "immich";
                    "app.kubernetes.io/name" = "machine-learning";
                  };
                  namespaces = [ "immich" ];
                  topologyKey = "kubernetes.io/hostname";
                };
              }
            ];
          };
        };
      };

      services.llama.spec = {
        type = "ClusterIP";
        selector.app = "llama";
        ports.http = {
          port = 80;
          targetPort = 8080;
        };
      };

      ingressRoutes.llama.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`llama.doma.lol`)";
            kind = "Rule";
            services.llama.port = 80;
          }
        ];
      };

      ingresses.llama.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "llama.doma.lol";
          }
        ];
      };

      services.llama-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "llama.doma.lol";
          "external-dns.alpha.kubernetes.io/target" = "homelab.boreal-scala.ts.net";
        };
        spec = {
          type = "ClusterIP";
          clusterIP = "None";
        };
      };
    };
  };
}
