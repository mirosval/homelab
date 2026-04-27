{ lib, ... }:
{
  applications.kata = {
    namespace = "kata-containers";
    createNamespace = true;

    helm.releases.kata = {
      chart = lib.helm.downloadHelmChart {
        repo = "oci://ghcr.io/kata-containers/kata-deploy-charts";
        chart = "kata-deploy";
        version = "3.29.0";
        chartHash = "sha256-E0qhF7beMGmxjrNu4Zx/KDKoDR93Wpmi/0gx8yj8acs=";
      };

      values = {
        k8sDistribution = "k3s";

        # Only enable cloud-hypervisor; disable all other hypervisors
        shims = {
          disableAll = true;
          clh.enabled = true;
        };

        # Create a single RuntimeClass named kata-clh
        runtimeClasses = {
          enabled = true;
          createDefault = true;
          defaultName = "kata-clh";
        };

        # Skip NFD — nodes already have kvm-intel loaded
        node-feature-discovery.enabled = false;
      };
    };
  };
}
