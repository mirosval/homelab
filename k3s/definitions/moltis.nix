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
            runtimeClassName = "kata-qemu";

            # Fresh Longhorn volumes mount root:root 0755; moltis runs as a
            # non-root user, so without this it can't create moltis.db under
            # /home/moltis/.moltis (SQLITE_CANTOPEN). fsGroup makes the mount
            # group-writable and adds that GID as a supplementary group to
            # every container in the pod.
            securityContext.fsGroup = 1000;

            initContainers = [
              # moltis.toml starts out as a ConfigMap subPath mount, but the
              # onboarding wizard needs to rewrite it (and provider_keys.json
              # next to it) at runtime. A ConfigMap subPath is a per-file bind
              # mount, so an atomic write (temp file + rename over the
              # target) hits EBUSY — can't rename onto an active mountpoint.
              # Seed it once onto the writable data PVC instead, so the app
              # owns a real file it can rewrite freely, and changes persist
              # across restarts.
              {
                name = "seed-config";
                image = "busybox:1.38.0";
                command = [
                  "sh"
                  "-c"
                  "test -f /home/moltis/.config/moltis/moltis.toml || cp /config-src/moltis.toml /home/moltis/.config/moltis/moltis.toml"
                ];
                volumeMounts = [
                  {
                    name = "config";
                    mountPath = "/config-src";
                    readOnly = true;
                  }
                  {
                    name = "data";
                    mountPath = "/home/moltis/.config/moltis";
                    subPath = "config";
                  }
                ];
              }
              # Native sidecar (restartPolicy Always): starts immediately and
              # keeps running, without blocking the rest of the init sequence
              # the way a regular container would. Must come before
              # wait-for-docker, which needs dockerd already listening.
              {
                name = "dind";
                image = "docker:29-dind";
                restartPolicy = "Always";
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
              }
              {
                name = "wait-for-docker";
                image = "docker:29-cli";
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
                    name = "data";
                    mountPath = "/home/moltis/.config/moltis";
                    subPath = "config";
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
