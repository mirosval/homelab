{ lib, ... }:
{
  applications.traefik = {
    namespace = "traefik";
    createNamespace = true;
    helm.releases.traefik = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://traefik.github.io/charts";
        chart = "traefik";
        version = "v37.1.1";
        chartHash = "sha256-h7jpw/wS9+XU7mIFn7T/sgZQPvH+XK4wHOFzy3TdFYg=";
      };
      values = {
        # volume for acme.json
        persistence = {
          enabled = true;
          storageClass = "longhorn";
        };
        # configure acme resolver
        certificatesResolvers.letsencrypt.acme = {
          email = "admin@doma.lol";
          dnsChallenge = {
            provider = "porkbun";
            resolvers = [
              "1.1.1.1"
            ];
          };
          storage = "/data/acme.json";
        };
        # bind secrets for the acme resolver
        env = [
          {
            name = "PORKBUN_API_KEY";
            valueFrom.secretKeyRef = {
              name = "lets-encrypt";
              key = "PORKBUN_API_KEY";
            };
          }
          {
            name = "PORKBUN_SECRET_API_KEY";
            valueFrom.secretKeyRef = {
              name = "lets-encrypt";
              key = "PORKBUN_SECRET_API_KEY";
            };
          }
        ];
        # ensure acme.json is 600
        deployment.initContainers = [
          {
            name = "volume-permissions";
            image = "busybox:latest";
            command = [
              "sh"
              "-c"
              "touch /data/acme.json; chmod -v 600 /data/acme.json"
            ];
            volumeMounts = [
              {
                mountPath = "/data";
                name = "data";
              }
            ];
          }
        ];
        # ensure k8s doesn't chmod the file after
        podSecurityContext = {
          fsGroup = 65532;
          fsGroupChangePolicy = "OnRootMismatch";
        };
        # redirect http -> https
        ports.web.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
          permanent = true;
        };
        # logging
        logs.access.enabled = true;
      };
    };
  };
}
