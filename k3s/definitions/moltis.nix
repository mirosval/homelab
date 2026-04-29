{ ... }:
{
  applications.moltis = {
    namespace = "moltis";
    createNamespace = true;

    resources = {
      configMaps.moltis-config.data."moltis.toml" = ''
        [tls]
        enabled = false

        [server]
        port = 13131
        bind = "0.0.0.0"

        [channels]
        offered = ["matrix"]

        [channels.matrix.homelab]
        homeserver = "http://matrix.matrix.svc.cluster.local"

        [providers.openai]
        enabled = true
        base_url = "http://llama.llama.svc.cluster.local/v1"
        api_key = "not-needed"
        fetch_models = true
      '';

      # Data: databases, sessions, memory files, logs
      persistentVolumeClaims.moltis-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "longhorn";
        resources.requests.storage = "5Gi";
      };

      deployments.moltis.spec = {
        replicas = 1;
        selector.matchLabels.app = "moltis";
        template = {
          metadata.labels.app = "moltis";
          spec = {
            runtimeClassName = "kata-clh";

            initContainers = [
              {
                name = "wait-for-docker";
                image = "docker:27-cli";
                command = [
                  "sh"
                  "-c"
                  "until docker info > /dev/null 2>&1; do sleep 1; done"
                ];
                env = [
                  {
                    name = "DOCKER_HOST";
                    value = "tcp://localhost:2375";
                  }
                ];
              }
            ];

            containers = {
              # Docker-in-Docker: runs dockerd inside the Kata microVM
              # Privileged here means privileged within the VM, not on the host
              dind = {
                image = "docker:27-dind";
                securityContext.privileged = true;
                env = [
                  {
                    name = "DOCKER_TLS_CERTDIR";
                    value = "";
                  }
                ];
                volumeMounts = [
                  {
                    name = "docker-graph";
                    mountPath = "/var/lib/docker";
                  }
                ];
              };

              moltis = {
                image = "ghcr.io/moltis-org/moltis:latest";
                ports.gateway.containerPort = 13131;
                env = [
                  {
                    name = "DOCKER_HOST";
                    value = "tcp://localhost:2375";
                  }
                ];
                envFrom = [
                  {
                    # Expects: MOLTIS_CHANNELS__MATRIX__HOMELAB__ACCESS_TOKEN
                    # and optionally external API keys
                    secretRef.name = "moltis";
                  }
                ];
                volumeMounts = [
                  {
                    name = "config";
                    mountPath = "/home/moltis/.config/moltis/moltis.toml";
                    subPath = "moltis.toml";
                    readOnly = true;
                  }
                  {
                    name = "data";
                    mountPath = "/home/moltis/.moltis";
                  }
                ];
                resources = {
                  requests = {
                    cpu = "100m";
                    memory = "256Mi";
                  };
                  limits = {
                    cpu = "2";
                    memory = "2Gi";
                  };
                };
              };
            };

            volumes = {
              config.configMap.name = "moltis-config";
              data.persistentVolumeClaim.claimName = "moltis-data";
              docker-graph.emptyDir = {};
            };
          };
        };
      };

      services.moltis.spec = {
        type = "ClusterIP";
        selector.app = "moltis";
        ports.gateway = {
          port = 13131;
          targetPort = 13131;
        };
      };

      ingressRoutes.moltis.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`moltis.doma.lol`)";
            kind = "Rule";
            services.moltis.port = 13131;
          }
        ];
      };

      ingresses.moltis.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "moltis.doma.lol";
          }
        ];
      };

      services.moltis-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "moltis.doma.lol";
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
