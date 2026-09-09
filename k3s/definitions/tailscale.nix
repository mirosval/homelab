{ lib, ... }:
{
  applications.tailscale = {
    namespace = "tailscale";
    createNamespace = true;
    helm.releases.tailscale = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://pkgs.tailscale.com/helmcharts";
        chart = "tailscale-operator";
        version = "1.102.3";
        chartHash = "sha256-yPwHKq8qXGdZlbNi9Y7fFd4PKRt0tHUTuVuh+HsyBiY=";
      };
    };

    resources = {
      # Override the secretName, this could not be configured via chart values, but the default was "operator-auth" which makes it difficult to distinguish from other operators
      deployments.operator.spec.template.spec.volumes.oauth.secret.secretName =
        lib.mkForce "tailscale-oauth";

    };
  };
}
