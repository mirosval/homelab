{ lib, ... }:
{
  applications.tailscale = {
    namespace = "tailscale";
    createNamespace = true;
    helm.releases.tailscale = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://pkgs.tailscale.com/helmcharts";
        chart = "tailscale-operator";
        version = "1.88.2";
        chartHash = "sha256-brC01veNdB36YY1OlDXuoM860or0SiP69uJv7BshuGQ=";
      };
    };
  };
}
