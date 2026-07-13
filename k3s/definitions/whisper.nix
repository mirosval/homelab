{ ... }:
{
  applications.whisper = {
    namespace = "whisper";
    createNamespace = true;
    resources = {

      persistentVolumeClaims.whisper-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "3Gi";
        storageClassName = "longhorn";
      };

      deployments.whisper.spec = {
        replicas = 1;
        selector.matchLabels.app = "whisper";
        template = {
          metadata.labels.app = "whisper";
          spec = {
            # Kept off homelab-01 (zigbee/home-assistant node) so STT/TTS
            # don't compete with home-assistant for CPU.
            nodeSelector."kubernetes.io/hostname" = "homelab-02";
            containers.whisper = {
              name = "whisper";
              image = "rhasspy/wyoming-whisper:3.3.0";
              args = [
                "--model"
                "small-int8"
                "--language"
                "en"
              ];
              ports = [ { containerPort = 10300; } ];
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
                persistentVolumeClaim.claimName = "whisper-data";
              }
            ];
          };
        };
      };

      services.whisper.spec = {
        type = "ClusterIP";
        selector.app = "whisper";
        ports.wyoming = {
          port = 10300;
          targetPort = 10300;
        };
      };

      networkPolicies.whisper.spec = {
        podSelector.matchLabels.app = "whisper";
        policyTypes = [ "Ingress" "Egress" ];
        ingress = [
          {
            from = [
              {
                namespaceSelector.matchLabels."kubernetes.io/metadata.name" = "home-assistant";
              }
            ];
            ports = [ { protocol = "TCP"; port = 10300; } ];
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
            # Needed to download the whisper model from Hugging Face on
            # first start. Persisted on the PVC afterwards.
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
