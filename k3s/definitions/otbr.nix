{ ... }:
{
  applications.otbr = {
    namespace = "otbr";
    createNamespace = true;
    resources = {

      deployments.otbr.spec = {
        replicas = 1;
        selector.matchLabels.app = "otbr";
        template = {
          metadata.labels.app = "otbr";
          spec = {
            nodeSelector.environment = "zigbee";
            containers.otbr = {
              name = "otbr";
              image = "openthread/border-router:v2026.07.0";
              securityContext = {
                privileged = true;
                capabilities.add = [ "NET_ADMIN" ];
              };
              env = [
                {
                  name = "OT_RCP_DEVICE";
                  value = "spinel+hdlc+uart:///dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_343cb516c0a3ef11977344bd61ce3355-if00-port0?uart-baudrate=460800";
                }
                {
                  name = "OT_INFRA_IF";
                  value = "eth0";
                }
                {
                  name = "OT_THREAD_IF";
                  value = "wpan0";
                }
                {
                  name = "OT_REST_LISTEN_ADDR";
                  value = "0.0.0.0";
                }
                {
                  name = "OT_REST_LISTEN_PORT";
                  value = "8081";
                }
              ];
              volumeMounts = [
                {
                  name = "thread-dongle";
                  mountPath = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_343cb516c0a3ef11977344bd61ce3355-if00-port0";
                }
                {
                  name = "tun";
                  mountPath = "/dev/net/tun";
                }
                {
                  name = "otbr-data";
                  mountPath = "/data";
                }
              ];
              ports = [ { containerPort = 8081; } ];
            };
            volumes = [
              {
                name = "thread-dongle";
                hostPath.path = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_343cb516c0a3ef11977344bd61ce3355-if00-port0";
              }
              {
                name = "tun";
                hostPath.path = "/dev/net/tun";
              }
              {
                name = "otbr-data";
                hostPath = {
                  path = "/var/lib/otbr";
                  type = "DirectoryOrCreate";
                };
              }
            ];
          };
        };
      };

      services.otbr.spec = {
        selector.app = "otbr";
        type = "ClusterIP";
        ports.rest = {
          port = 8081;
          targetPort = 8081;
        };
      };

      networkPolicies.otbr.spec = {
        podSelector.matchLabels.app = "otbr";
        policyTypes = [ "Ingress" "Egress" ];
        ingress = [
          {
            from = [
              {
                namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "home-assistant";
              }
            ];
            ports = [ { protocol = "TCP"; port = 8081; } ];
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
    };
  };
}
