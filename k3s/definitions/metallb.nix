{ lib, ... }:
{
  applications.metallb = {
    namespace = "metallb";
    createNamespace = true;
    helm.releases.metallb = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://metallb.github.io/metallb";
        chart = "metallb";
        version = "0.16.1";
        chartHash = "sha256-Z1qB6M5XxM3VXkYBzgDOjGLaoR7ICzffXT4OaDruP8k=";
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
