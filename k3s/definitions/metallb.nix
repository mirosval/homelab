{ lib, ... }:
{
  applications.metallb = {
    namespace = "metallb";
    createNamespace = true;
    helm.releases.metallb = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://metallb.github.io/metallb";
        chart = "metallb";
        version = "0.15.2";
        chartHash = "sha256-jAb+SA0/N7KqYUL9t5KDQjUN73D/01akCyB3tf+Id9g=";
      };
      values = { };
    };

    resources.ipAddressPools.pool.spec.addresses = [
      "10.42.1.0/24"
    ];

    resources.l2Advertisements.pool.spec.ipAddressPools = [
      "pool"
    ];
  };
}
