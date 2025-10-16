{ lib, ... }:
{
  applications.cilium = {
    namespace = "kube-system";
    createNamespace = false;
    helm.releases.cilium = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://helm.cilium.io";
        chart = "cilium";
        version = "v1.18.2";
        chartHash = "sha256-V6v+786h++de7dLTZfP7EmTD6MMkUlZTNEAiOX8x8us=";
      };

      values = {
        ipv4.enabled = true;
        ipv6.enabled = false;
        kubeProxyReplacement = true;
        k8sServiceHost = "10.42.0.4";
        k8sServicePort = "6443";
        ipam.mode = "cluster-pool";
        ipam.operator.clusterPoolIPv4PodCIDRList = [ "10.44.0.0/16" ];
        ipam.operator.clusterPoolIPv4MaskSize = 24;
        encryption = {
          enabled = true;
          type = "wireguard";
        };
      };
    };
  };
}
