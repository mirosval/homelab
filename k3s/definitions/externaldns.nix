{ lib, ... }:
let
  externalDnsChart = lib.helm.downloadHelmChart {
    repo = "https://kubernetes-sigs.github.io/external-dns/";
    chart = "external-dns";
    version = "1.19";
    chartHash = "sha256-qzmJ1wtxoFlLZNufoMX5U5U+YKjQSLJXQJRxXY+gRsk=";
  };
in
{
  applications.external-dns = {
    namespace = "external-dns";
    createNamespace = true;
    helm.releases.external-dns = {
      chart = externalDnsChart;

      values = {
        provider = "pihole";
        txtOwnerId = "homelab";
        sources = [ "ingress" ];
        extraArgs = [ "--ingress-class=traefik" ];
        env = [
          {
            name = "EXTERNAL_DNS_PIHOLE_API_VERSION";
            value = "6";
          }
          {
            name = "EXTERNAL_DNS_PIHOLE_SERVER";
            value = "http://pihole-web.pihole.svc.cluster.local";
          }
          {
            name = "EXTERNAL_DNS_PIHOLE_PASSWORD";
            valueFrom.secretKeyRef = {
              name = "pihole-password";
              key = "password";
            };
          }
        ];
      };
    };
  };

  applications.external-dns-ts = {
    namespace = "external-dns-ts";
    createNamespace = true;
    helm.releases.external-dns-ts = {
      chart = externalDnsChart;

      values = {
        provider = "pihole";
        txtOwnerId = "homelab-ts";
        sources = [ "service" ];
        annotationFilter = "external-dns.alpha.kubernetes.io/target";
        env = [
          {
            name = "EXTERNAL_DNS_PIHOLE_API_VERSION";
            value = "6";
          }
          {
            name = "EXTERNAL_DNS_PIHOLE_SERVER";
            value = "http://pihole-ts-web.pihole-ts.svc.cluster.local";
          }
          {
            name = "EXTERNAL_DNS_PIHOLE_PASSWORD";
            valueFrom.secretKeyRef = {
              name = "pihole-ts-password";
              key = "password";
            };
          }
        ];
      };
    };
  };
}
