{ lib, ... }:
{
  applications.forgejo = {
    namespace = "forgejo";
    createNamespace = true;
    helm.releases.forgejo = {
      chart = lib.helm.downloadHelmChart {
        repo = "oci://code.forgejo.org/forgejo-helm";
        chart = "forgejo";
        version = "14.0.4";
        chartHash = "sha256-j2Wd9b6ds9QayKYPjxqlKBXZvmuQd3F6l/68PzBCkFY=";
      };

      values = {
        global = {
          storageClass = "longhorn";
          hostnames = [ "forgejo.doma.lol" ];
        };
        gitea = {
          admin.existingSecret = "forgejo";
          config.server = {
            DOMAIN = "forgejo.doma.lol";
            ROOT_URL = "https://forgejo.doma.lol";
          };
        };
      };
    };

    resources = {
      # Runners
      deployments.forgejo-runner.spec = {
        replicas = 1;
        selector.matchLabels.app = "forgejo-runner";
        template = {
          metadata.labels.app = "forgejo-runner";
          spec = {
            automountServiceAccountToken = true;
            restartPolicy = "Always";
            initContainers = [
              {
                name = "runner-register";

                image = "code.forgejo.org/forgejo/runner:11.3.1";
                command = [
                  "/bin/bash"
                  "-c"
                ];
                args = [
                  ''
                    while : ; do
                      forgejo-runner register --no-interactive --token $(RUNNER_SECRET) --name $(RUNNER_NAME) --instance $(FORGEJO_INSTANCE_URL) && break ;
                      sleep 1 ;
                    done ;
                    forgejo-runner generate-config > /data/config.yml ;
                    sed -i -e "s|network: .*|network: host|" config.yml ;
                    sed -i -e "s|^  envs:$$|  envs:\n    DOCKER_HOST: tcp://localhost:2376\n    DOCKER_TLS_VERIFY: 1\n    DOCKER_CERT_PATH: /certs/client|" config.yml ;
                    sed -i -e "s|^  options:|  options: -v /certs/client:/certs/client|" config.yml ;
                    sed -i -e "s|  valid_volumes: \[\]$$|  valid_volumes:\n    - /certs/client|" config.yml
                  ''
                ];
                env = [
                  {
                    name = "RUNNER_NAME";
                    valueFrom.fieldRef.fieldPath = "metadata.name";
                  }
                  {
                    name = "RUNNER_SECRET";
                    valueFrom.secretKeyRef = {
                      name = "forgejo-runner";
                      key = "token";
                    };
                  }
                  {
                    name = "FORGEJO_INSTANCE_URL";
                    value = "http://forgejo-http.forgejo.svc.cluster.local:3000";
                  }
                ];
                volumeMounts = [
                  {
                    name = "runner-data";
                    mountPath = "/data";
                  }
                ];
                securityContext = {
                  allowPrivilegeEscalation = false;
                  capabilities.drop = [ "ALL" ];
                  privileged = false;
                  readOnlyRootFilesystem = true;
                  runAsNonRoot = true;
                  seccompProfile.type = "RuntimeDefault";
                };
              }
            ];
            containers = {
              runner = {
                image = "code.forgejo.org/forgejo/runner:11.3.1";
                command = [
                  "/bin/bash"
                  "-c"
                ];

                args = [
                  ''
                    while ! nc -z localhost 2376 </dev/null ; do
                      echo 'waiting for docker daemon...' ;
                      sleep 5 ;
                      done ;
                    forgejo-runner --config config.yml daemon
                  ''
                ];
                env = [
                  {
                    name = "DOCKER_HOST";
                    value = "tcp://localhost:2376";
                  }
                  {
                    name = "DOCKER_CERT_PATH";
                    value = "/certs/client";
                  }
                  {
                    name = "DOCKER_TLS_VERIFY";
                    value = "1";
                  }

                ];
                volumeMounts = [
                  {
                    name = "docker-certs";
                    mountPath = "/certs";

                  }
                  {
                    name = "runner-data";
                    mountPath = "/data";

                  }
                  {
                    name = "tmp";
                    mountPath = "/tmp";

                  }
                ];
                securityContext = {
                  allowPrivilegeEscalation = false;
                  capabilities.drop = [
                    "ALL"
                  ];
                  privileged = false;
                  readOnlyRootFilesystem = true;
                  runAsNonRoot = true;
                  seccompProfile.type = "RuntimeDefault";
                };
              };
              daemon = {
                image = "docker.io/docker:29.0.0-dind";
                env = [
                  {
                    name = "DOCKER_TLS_CERTDIR";
                    value = "/certs";
                  }
                ];
                securityContext.privileged = true;
                volumeMounts = [
                  {
                    name = "docker-certs";
                    mountPath = "/certs";

                  }
                ];
              };
            };
            volumes = [
              {
                name = "docker-certs";
                emptyDir = { };
              }
              {
                name = "runner-data";
                emptyDir = { };
              }
              {
                name = "tmp";
                emptyDir = { };
              }
            ];
          };
        };
      };

      # Ingress
      ingressRoutes.forgejo.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`forgejo.doma.lol`)";
            kind = "Rule";
            services.forgejo-http.port = 3000;
          }
        ];
      };

      ingresses.forgejo.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "forgejo.doma.lol";
          }
        ];
      };
    };
  };
}
