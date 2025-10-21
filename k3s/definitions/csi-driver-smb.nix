{ lib, ... }:
{
  applications.csi-driver-smb = {
    namespace = "csi-driver-smb";
    createNamespace = true;
    helm.releases.csi-driver-smb = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts";
        chart = "csi-driver-smb";
        version = "1.19.1";
        chartHash = "sha256-r4BQC+6VKn0Jsbghb+rJhw6gCWWetOSnKQlBfwZVLVs=";
      };

      values = {
        windows.enabled = false;
      };
    };
  };
}
