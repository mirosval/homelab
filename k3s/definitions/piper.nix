{ ... }:
{
  applications.piper = {
    namespace = "piper";
    createNamespace = true;
    resources = {

      persistentVolumeClaims.piper-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "1Gi";
        storageClassName = "longhorn";
      };

      deployments.piper.spec = {
        replicas = 1;
        selector.matchLabels.app = "piper";
        template = {
          metadata.labels.app = "piper";
          spec = {
            # Kept off homelab-01 (zigbee/home-assistant node) and off
            # homelab-02 (whisper) so each voice service has its own node.
            nodeSelector."kubernetes.io/hostname" = "homelab-03";
            containers.piper = {
              name = "piper";
              image = "rhasspy/wyoming-piper:2.2.2";
              args = [
                "--voice"
                "en_US-lessac-medium"
              ];
              ports = [ { containerPort = 10200; } ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
              ];
            };
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "piper-data";
              }
            ];
          };
        };
      };

      services.piper.spec = {
        type = "ClusterIP";
        selector.app = "piper";
        ports.wyoming = {
          port = 10200;
          targetPort = 10200;
        };
      };

      networkPolicies.piper.spec = {
        podSelector.matchLabels.app = "piper";
        policyTypes = [ "Ingress" "Egress" ];
        ingress = [
          {
            from = [
              {
                namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "home-assistant";
              }
            ];
            ports = [ { protocol = "TCP"; port = 10200; } ];
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
          {
            # Needed to download the piper voice on first start. Persisted
            # on the PVC afterwards.
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
