{ lib, ... }:
{
  applications.tailscale = {
    namespace = "tailscale";
    createNamespace = true;
    helm.releases.tailscale = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://pkgs.tailscale.com/helmcharts";
        chart = "tailscale-operator";
        version = "1.98.9";
        chartHash = "sha256-Xav0I55wfaV1RbfOQP5HA2L7cU48ShJPe/Zl5JNDW8o=";
      };
    };

    resources = {
      # Override the secretName, this could not be configured via chart values, but the default was "operator-auth" which makes it difficult to distinguish from other operators
      deployments.operator.spec.template.spec.volumes.oauth.secret.secretName =
        lib.mkForce "tailscale-oauth";

    };
  };
}
