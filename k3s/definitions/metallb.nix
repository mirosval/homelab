{ lib, ... }:
{
  applications.metallb = {
    namespace = "metallb";
    createNamespace = true;
    helm.releases.metallb = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://metallb.github.io/metallb";
        chart = "metallb";
        version = "0.15.3";
        chartHash = "sha256-KWdVaF6CjFjeHQ6HT1WvkI9JnSurt9emLVCpkxma0fg=";
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
