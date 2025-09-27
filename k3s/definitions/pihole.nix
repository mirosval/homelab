{ lib, ... }:
{
  applications.pihole = {
    namespace = "pihole";
    createNamespace = true;
    helm.releases.pihole = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://mojo2600.github.io/pihole-kubernetes/";
        chart = "pihole";
        version = "v2.34.0";
        chartHash = "sha256-nhvifpDdM8MoxF43cJAi6o+il2BbHX+udVAvvm1PukM=";
      };
    };
  };
}
