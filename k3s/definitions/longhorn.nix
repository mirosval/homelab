{ lib, ... }:
{
  applications.longhorn = {
    namespace = "longhorn";
    createNamespace = true;
    helm.releases.longhorn = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.longhorn.io";
        chart = "longhorn";
        version = "1.9.1";
        chartHash = "sha256-jDI7vHl0QNAgFEgAdPf8HoG7OcnRED3QNMSN+tFoxaI=";
      };
      values = { };
    };
  };
}
