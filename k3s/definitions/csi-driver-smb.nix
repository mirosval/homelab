{ lib, ... }:
{
  applications.csi-driver-smb = {
    namespace = "csi-driver-smb";
    createNamespace = true;
    helm.releases.csi-driver-smb = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts";
        chart = "csi-driver-smb";
        version = "1.20.1";
        chartHash = "sha256-BvAdwwAXTxJi+plCxG90CMbebWNPU4OuYPAR0OOIiGs=";
      };

      values = {
        windows.enabled = false;
      };
    };
  };
}
