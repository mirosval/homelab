{ lib, ... }:
{
  applications.flannel = {
    namespace = "kube-flannel";
    createNamespace = true;
    helm.releases.flannel = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://flannel-io.github.io/flannel/";
        chart = "flannel";
        version = "v0.27.4";
        chartHash = "sha256-Kcm+AnlViqYrsvVvLWpkolL5R86O0i7aS+58JqsrJbs=";
      };

      values = {
        flannel.backend = "wireguard";
      };
    };
  };
}
