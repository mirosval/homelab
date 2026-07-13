{ ... }:
{
  applications.matter-server = {
    namespace = "matter-server";
    createNamespace = true;
    resources = {

      persistentVolumeClaims.matter-server-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "1Gi";
        storageClassName = "longhorn";
      };

      # Shared with the paa-cert-fetcher CronJob. Longhorn's ReadWriteOnce
      # restricts the volume to a single *node*, not a single pod - both
      # matter-server and the fetcher are pinned to homelab-01, so they can
      # mount this concurrently.
      persistentVolumeClaims.matter-server-paa-certs-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "100Mi";
        storageClassName = "longhorn";
      };

      deployments.matter-server.spec = {
        replicas = 1;
        selector.matchLabels.app = "matter-server";
        template = {
          metadata.labels.app = "matter-server";
          spec = {
            nodeSelector.environment = "zigbee";
            containers.matter-server = {
              name = "matter-server";
              image = "ghcr.io/home-assistant-libs/python-matter-server:8.1.0";
              securityContext = {
                privileged = true;
                capabilities.add = [ "NET_ADMIN" "NET_RAW" ];
              };
              args = [
                "--storage-path"
                "/data"
                "--port"
                "5580"
                "--paa-root-cert-dir"
                "/paa-root-certs"
                "--bluetooth-adapter"
                "0"
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
                {
                  name = "paa-certs";
                  mountPath = "/paa-root-certs";
                }
                {
                  name = "d-bus";
                  mountPath = "/run/dbus";
                }
              ];
              ports = [ { containerPort = 5580; } ];
            };
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "matter-server-data";
              }
              {
                name = "paa-certs";
                persistentVolumeClaim.claimName = "matter-server-paa-certs-data";
              }
              {
                name = "d-bus";
                hostPath.path = "/run/dbus";
              }
            ];
          };
        };
      };

      services.matter-server.spec = {
        selector.app = "matter-server";
        type = "ClusterIP";
        ports.ws = {
          port = 5580;
          targetPort = 5580;
        };
      };

      networkPolicies.matter-server.spec = {
        podSelector.matchLabels.app = "matter-server";
        policyTypes = [ "Ingress" "Egress" ];
        ingress = [
          {
            from = [
              {
                namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "home-assistant";
              }
            ];
            ports = [ { protocol = "TCP"; port = 5580; } ];
          }
        ];
        egress = [
          {
            to = [
              {
                namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "kube-system";
              }
            ];
            ports = [
              { protocol = "UDP"; port = 53; }
              { protocol = "TCP"; port = 53; }
            ];
          }
        ];
      };

      # Fetches PAA root certificates from GitHub and writes them to the
      # shared PVC. This is the only component in the matter-server
      # namespace allowed internet egress - matter-server itself never
      # needs to reach out, since the certs are already on disk (and its
      # own 24h freshness check skips re-fetching once a .version marker
      # is present).
      cronJobs.paa-cert-fetcher.spec = {
        schedule = "0 3 * * *";
        concurrencyPolicy = "Forbid";
        jobTemplate.spec.template = {
          metadata.labels.app = "paa-cert-fetcher";
          spec = {
            restartPolicy = "OnFailure";
            nodeSelector.environment = "zigbee";
            containers.paa-cert-fetcher = {
              name = "paa-cert-fetcher";
              image = "alpine:3.20";
              command = [ "/bin/sh" "-c" ];
              args = [
                ''
                  set -eu
                  apk add --no-cache curl jq >/dev/null
                  dest=/paa-root-certs
                  base="https://raw.githubusercontent.com/project-chip/connectedhomeip/master/credentials/development/paa-root-certs"
                  tmp="$(mktemp -d)"
                  curl -sf "https://api.github.com/repos/project-chip/connectedhomeip/contents/credentials/development/paa-root-certs" \
                    | jq -r '.[].name' > "$tmp/files.txt"
                  while IFS= read -r name; do
                    curl -sf "$base/$name" -o "$tmp/$name"
                  done < "$tmp/files.txt"
                  touch "$tmp/.version"
                  rm -f "$dest"/*.pem "$dest"/*.der 2>/dev/null || true
                  cp "$tmp"/* "$dest"/
                  cp "$tmp/.version" "$dest/.version"
                  echo "Fetched $(wc -l < "$tmp/files.txt") PAA certificate files."
                ''
              ];
              volumeMounts = [
                {
                  name = "paa-certs";
                  mountPath = "/paa-root-certs";
                }
              ];
            };
            volumes = [
              {
                name = "paa-certs";
                persistentVolumeClaim.claimName = "matter-server-paa-certs-data";
              }
            ];
          };
        };
      };

      networkPolicies.paa-cert-fetcher.spec = {
        podSelector.matchLabels.app = "paa-cert-fetcher";
        policyTypes = [ "Egress" ];
        egress = [
          {
            to = [
              {
                namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "kube-system";
              }
            ];
            ports = [
              { protocol = "UDP"; port = 53; }
              { protocol = "TCP"; port = 53; }
            ];
          }
          {
            to = [
              {
                ipBlock = {
                  cidr = "0.0.0.0/0";
                  except = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ];
                };
              }
            ];
            ports = [ { protocol = "TCP"; port = 443; } ];
          }
        ];
      };
    };
  };
}
