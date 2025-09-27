{ lib, ... }:
{
  applications.external-dns = {
    namespace = "external-dns";
    createNamespace = true;
    helm.releases.external-dns = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://kubernetes-sigs.github.io/external-dns/";
        chart = "external-dns";
        version = "1.19";
        chartHash = "sha256-qzmJ1wtxoFlLZNufoMX5U5U+YKjQSLJXQJRxXY+gRsk=";
      };

      values = {
        provider = "pihole";
        txtOwnerId = "homelab";
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
}
