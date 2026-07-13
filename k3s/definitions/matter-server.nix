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

      deployments.matter-server.spec = {
        replicas = 1;
        selector.matchLabels.app = "matter-server";
        template = {
          metadata.labels.app = "matter-server";
          spec = {
            nodeSelector.environment = "zigbee";
            containers.matter-server = {
              name = "matter-server";
              image = "ghcr.io/home-assistant-libs/python-matter-server:8.1.2";
              args = [
                "--storage-path"
                "/data"
                "--port"
                "5580"
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
              ];
              ports = [ { containerPort = 5580; } ];
            };
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "matter-server-data";
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
    };
  };
}
