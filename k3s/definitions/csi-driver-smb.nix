{ lib, ... }:
{
  applications.csi-driver-smb = {
    namespace = "csi-driver-smb";
    createNamespace = true;
    helm.releases.csi-driver-smb = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts";
        chart = "csi-driver-smb";
        version = "1.20.3";
        chartHash = "sha256-oYlLbFIRNbb0khqikf89yG3v9cryanDSdh9q8+7eQeE=";
      };

      values = {
        windows.enabled = false;
      };
    };
  };
}
