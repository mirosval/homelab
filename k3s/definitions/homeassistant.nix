{ ... }:
{
  applications.home-assistant = {
    namespace = "home-assistant";
    createNamespace = true;
    resources = {

      deployments.home-assistant.spec = {
        replicas = 1;
        selector.matchLabels.app = "home-assistant";
        template = {
          metadata.labels.app = "home-assistant";
          spec = {
            containers.home-assistant = {
              name = "home-assistant";
              image = "ghcr.io/home-assistant/home-assistant:stable";
              securityContext.privileged = true;
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
              ];
            };
            hostNetwork = true;
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
            ];
          };
        };
      };

      services.home-assistant.spec = {
        ports.home-assistant-web.port = 8123;
        selector.app = "home-assistant";
        type = "ClusterIP";
      };

      # services.home-assistant-lb.spec = {
      #   ports.home-assistant-web.port = 8123;
      #   selector.app = "home-assistant";
      #   type = "LoadBalancer";
      # };

      persistentVolumeClaims.home-assistant-pvc.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "512Mi";
        storageClassName = "longhorn";
      };

    };
  };
}
