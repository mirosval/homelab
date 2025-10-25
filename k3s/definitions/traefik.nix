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
        # redirect http -> https
        ports.web.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
          permanent = true;
        };
        # Allow bigger payloads
        ports.web.transport.respondingTimeouts = {
          readTimeout = 0;
          writeTimeout = 0;
          idleTimeout = 0;
        };
        ports.websecure.transport.respondingTimeouts = {
          readTimeout = 0;
          writeTimeout = 0;
          idleTimeout = 0;
        };
        # logging
        logs.access.enabled = true;
        # tls
        tlsStore.default.defaultCertificate.secretName = "wildcard-doma-lol-tls";
        ingressRoute.dashboard = {
          # dashboard
          enabled = true;
          entryPoints = [ "websecure" ];
          matchRule = "Host(`traefik.doma.lol`)";
          middlewares = [
            { name = "traefik-auth"; }
          ];
        };
      };
    };

    resources = {

      # cert-manager
      issuers.cloudflare-issuer.spec.acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory";
        email = "admin@doma.lol";
        privateKeySecretRef.name = "letsencrypt-key";
        solvers = [
          {
            dns01.cloudflare.apiTokenSecretRef = {
              name = "cloudflare-token";
              key = "api-key";
            };
          }
        ];
      };

      certificates.wildcard-doma-lol.spec = {
        secretName = "wildcard-doma-lol-tls";
        dnsNames = [
          "doma.lol"
          "*.doma.lol"
        ];
        issuerRef = {
          name = "cloudflare-issuer";
          kind = "Issuer";
        };
      };

      ingresses.tailscale.spec = {
        defaultBackend.service = {
          name = "traefik";
          port.name = "websecure";
        };
        ingressClassName = "tailscale";
        tls = [ { hosts = [ "homelab" ]; } ];
      };

      middlewares.traefik-auth.spec.basicAuth.secret = "traefik-auth";

      ingresses.traefik-dash.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "traefik.doma.lol";
          }
        ];
      };
    };
  };
}
