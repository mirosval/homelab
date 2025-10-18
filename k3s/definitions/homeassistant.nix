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
                {
                  mountPath = "/dev/ttyUSB0";
                  name = "zigbee";
                }
              ];
              ports = [ { containerPort = 8123; } ];
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
                hostPath.path = "/dev/ttyUSB0";
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
        resources.requests.storage = "512Mi";
        storageClassName = "longhorn";
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
    };
  };
}
