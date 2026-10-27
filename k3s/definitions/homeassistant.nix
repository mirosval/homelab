{ ... }:
{
  applications.home-assistant = {
    namespace = "home-assistant";
    createNamespace = true;
    resources = {

      deployments.home-assistant.spec = {
        replicas = 1;
        # HA refuses to start while another instance holds the same /config
        strategy.type = "Recreate";
        selector.matchLabels.app = "home-assistant";
        template = {
          metadata.labels.app = "home-assistant";
          spec = {
            containers.home-assistant = {
              name = "home-assistant";
              image = "ghcr.io/home-assistant/home-assistant:2026.4.2";
              securityContext = {
                privileged = true;
                capabilities.add = [
                  "NET_ADMIN"
                  "NET_RAW"
                ];
              };
              env = [
                {
                  name = "TZ";
                  value = "Europe/Berlin";
                }
              ];
              volumeMounts = [
                {
                  mountPath = "/config";
                  name = "home-assistant-config-volume";
                }
                {
                  mountPath = "/run/dbus";
                  name = "d-bus";
                }
                {
                  mountPath = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_cc5121307674ef11af55c48c8fcc3fa0-if00-port0";
                  name = "zigbee";
                }
              ];
              ports = [ { containerPort = 8123; } ];
            };
            # Tessera ESP screen manager. Runs as a sidecar so it reaches HA on localhost.
            containers.tessera = {
              name = "tessera";
              image = "ghcr.io/maxgramser/homeassistant_espscreen:0.4.90";
              env = [
                {
                  name = "TZ";
                  value = "Europe/Berlin";
                }
                {
                  name = "SCREEN_DEV";
                  value = "1";
                }
                {
                  name = "HA_API";
                  value = "http://127.0.0.1:8123/api";
                }
                {
                  name = "HA_TOKEN_FILE";
                  value = "/tessera-secrets/ha_token";
                }
                {
                  name = "ESPHOME_CONFIG";
                  value = "/config";
                }
                {
                  name = "SCREEN_DATA";
                  value = "/data";
                }
              ];
              volumeMounts = [
                {
                  mountPath = "/config";
                  name = "tessera-esphome";
                }
                {
                  mountPath = "/data";
                  name = "tessera-data";
                }
                {
                  mountPath = "/tessera-secrets";
                  name = "tessera-ha-token";
                  readOnly = true;
                }
              ];
              ports = [
                { containerPort = 8099; }
                { containerPort = 8098; }
              ];
              # Tessera's UI listens on 127.0.0.1 only, so the kubelet can't probe the pod IP.
              readinessProbe.exec.command = [
                "curl"
                "--fail"
                "--silent"
                "--output"
                "/dev/null"
                "http://127.0.0.1:8099/health"
              ];
              livenessProbe = {
                exec.command = [
                  "curl"
                  "--fail"
                  "--silent"
                  "--output"
                  "/dev/null"
                  "http://127.0.0.1:8099/health"
                ];
                initialDelaySeconds = 30;
              };
            };
            # Installs the hass_ingress custom integration (sidebar proxy for Tessera's loopback-only UI)
            # into /config/custom_components. Pinned release, checksum verified. Skips when that version
            # is already installed, and never fails: a bad download must not keep Home Assistant from starting.
            initContainers.install-hass-ingress = {
              name = "install-hass-ingress";
              image = "alpine:3.22";
              command = [
                "sh"
                "-c"
                ''
                  VERSION=1.4.0
                  SHA256=7b2255fa3f25b97d465c17336cae8188bcc4dfefd52677682f084c1e39a54cac
                  DIR=/config/custom_components/ingress
                  TMP=/config/custom_components/.ingress-new

                  if grep -q "\"version\": \"$VERSION\"" "$DIR/manifest.json" 2>/dev/null; then
                    echo "hass_ingress $VERSION already installed, nothing to do"
                    exit 0
                  fi

                  rm -rf "$TMP" /tmp/ingress.zip
                  if timeout 120 wget -q -T 30 -O /tmp/ingress.zip "https://github.com/lovelylain/hass_ingress/releases/download/$VERSION/ingress.zip" \
                    && echo "$SHA256  /tmp/ingress.zip" | sha256sum -c - \
                    && mkdir -p "$TMP" \
                    && unzip -q /tmp/ingress.zip -d "$TMP" \
                    && grep -q "\"version\": \"$VERSION\"" "$TMP/manifest.json" \
                    && rm -rf "$DIR" \
                    && mv "$TMP" "$DIR"; then
                    echo "installed hass_ingress $VERSION"
                  else
                    echo "WARNING: could not install hass_ingress $VERSION, continuing without changes"
                    rm -rf "$TMP"
                  fi
                  exit 0
                ''
              ];
              volumeMounts = [
                {
                  mountPath = "/config";
                  name = "home-assistant-config-volume";
                }
              ];
            };
            # hostNetwork = true;
            nodeSelector.environment = "zigbee";
            volumes = [
              {
                name = "home-assistant-config-volume";
                persistentVolumeClaim.claimName = "home-assistant-pvc";
              }
              {
                name = "d-bus";
                hostPath.path = "/run/dbus";
              }
              {
                name = "zigbee";
                hostPath.path = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_cc5121307674ef11af55c48c8fcc3fa0-if00-port0";
              }
              {
                name = "tessera-esphome";
                persistentVolumeClaim.claimName = "tessera-esphome-pvc";
              }
              {
                name = "tessera-data";
                persistentVolumeClaim.claimName = "tessera-data-pvc";
              }
              {
                name = "tessera-ha-token";
                secret.secretName = "tessera";
              }
            ];
          };
        };
      };

      services.home-assistant-lb.spec = {
        selector.app = "home-assistant";
        type = "LoadBalancer";
        ports = [
          {
            port = 8123;
            targetPort = 8123;
          }
        ];
      };

      services.home-assistant-web.spec = {
        ports.home-assistant-web.port = 8123;
        selector.app = "home-assistant";
        type = "ClusterIP";
      };

      persistentVolumeClaims.home-assistant-pvc.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "10Gi";
        storageClassName = "longhorn";
      };

      persistentVolumeClaims.tessera-esphome-pvc.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "2Gi";
        storageClassName = "longhorn";
      };

      persistentVolumeClaims.tessera-data-pvc.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "10Gi";
        storageClassName = "longhorn";
      };

      # Port 8098, used by the ESP screens (on a separate VLAN), so it needs a stable LAN IP.
      services.tessera-screens-lb = {
        metadata.annotations."metallb.universe.tf/address-pool" = "pool";
        spec = {
          selector.app = "home-assistant";
          type = "LoadBalancer";
          loadBalancerIP = "10.42.1.3";
          ports = [
            {
              port = 8098;
              targetPort = 8098;
            }
          ];
        };
      };

      ingressRoutes.home-assistant.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`home-assistant.doma.lol`)";
            kind = "Rule";
            services.home-assistant-web.port = 8123;
          }
        ];
        tls = {
          certResolver = "letsencrypt";
          domains = [
            {
              main = "doma.lol";
              sans = [ "*.doma.lol" ];
            }
          ];
        };
      };

      ingresses.home-assistant.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "home-assistant.doma.lol";
          }
        ];
      };

      services.home-assistant-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "home-assistant.doma.lol";
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
