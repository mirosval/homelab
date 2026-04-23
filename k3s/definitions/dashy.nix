{ ... }:
{
  applications.dashy = {
    namespace = "dashy";
    createNamespace = true;
    resources = {
      deployments.dashy.spec = {
        replicas = 1;
        selector.matchLabels.app = "dashy";

        template = {
          metadata.labels.app = "dashy";

          spec = {
            containers.dashy = {
              image = "lissy93/dashy@sha256:f656ea52c16801a5e9a80353616b76a8537e4d1a73900cb0ecfae786ce7ddf66";
              ports.http.containerPort = 8080;
              env = {
                NODE_ENV.value = "production";
              };

              volumeMounts = [
                {
                  name = "config";
                  mountPath = "/app/user-data";
                  readOnly = true;
                }
              ];
            };
            volumes.config.configMap.name = "dashy-config";
          };
        };
      };

      services.dashy.spec = {
        type = "ClusterIP";
        selector.app = "dashy";

        ports.http = {
          port = 80;
          targetPort = 8080;
        };
      };

      configMaps.dashy-config.data = {
        "conf.yml" = ''
          pageInfo:
            title: doma.lol

          appConfig:
            statusCheck: true
            theme: crayola
            preventWriteToDisk: true
            disableConfiguration: true
            hideComponents:
              hideSettings: true
              hideFooter: true

          sections:
            - name: Apps
              items:
                - title: Immich
                  description: View and manage photos
                  url: https://immich.doma.lol
                  icon: hl-immich
                - title: Jellyfin
                  description: Watch Movies and TV Shows
                  url: https://jellyfin.doma.lol
                  icon: hl-jellyfin
                - title: Paperless
                  description: Documents management
                  url: https://paperless.doma.lol
                  icon: hl-paperless-ngx
                - title: Home Assistant
                  description: Automation
                  url: https://home-assistant.doma.lol
                  icon: hl-home-assistant
                - title: Dazzle
                  description: Weather Display Bathroom
                  url: https://dazzle.doma.lol/dashboard
                  icon: fas fa-umbrella
                - title: Vaultwarden
                  description: Password Manager
                  url: https://vaultwarden.doma.lol
                  icon: hl-vaultwarden
                - title: Llama
                  description: Local LLM
                  url: https://llama.doma.lol
                  icon: hl-ollama
                - title: Element
                  description: Matrix Chat
                  url: https://element.doma.lol
                  icon: hl-element
            - name: Network
              items:
                - title: ISP
                  description: Router Settings
                  url: http://192.168.0.1
                  icon: hl-router
                - title: UniFi
                  description: Network setup
                  url: http://10.42.0.1
                  icon: hl-unifi
                - title: Traefik
                  description: Reverse Proxy
                  url: https://traefik.doma.lol
                  icon: hl-traefik
                - title: Pihole
                  description: DNS Blocking
                  url: https://pihole.doma.lol
                  icon: hl-pihole
            - name: Homelab
              items:
                - title: Longhorn
                  description: Volume Management
                  url: https://longhorn.doma.lol
                  icon: hl-longhorn
                - title: Argo
                  description: GitOps
                  url: https://argo.doma.lol
                  icon: hl-argocd
                - title: Forgejo
                  description: Git Hosting
                  url: https://forgejo.doma.lol
                  icon: hl-forgejo
            - name: Monitoring
              items:
                - title: Grafana
                  description: Fancy Graphs
                  url: https://grafana.doma.lol
                  icon: hl-grafana
        '';
      };

      ingressRoutes.dashy.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`dashy.doma.lol`)";
            kind = "Rule";
            services.dashy.port = 80;
          }
        ];
      };

      ingresses.dashy.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "dashy.doma.lol";
          }
        ];
      };

      services.dashy-tailscale = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "dashy.doma.lol";
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
