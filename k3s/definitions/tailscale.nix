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

    resources = {
      # Override the secretName, this could not be configured via chart values, but the default was "operator-auth" which makes it difficult to distinguish from other operators
      deployments.operator.spec.template.spec.volumes.oauth.secret.secretName =
        lib.mkForce "tailscale-oauth";

    };
  };
}
