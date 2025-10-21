{ lib, ... }:
{
  applications.longhorn = {
    namespace = "longhorn";
    createNamespace = true;
    helm.releases.longhorn = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.longhorn.io";
        chart = "longhorn";
        version = "1.10.0";
        chartHash = "sha256-jDI7vHl0QNAgFEgAdPf8HoG7OcnRED3QNMSN+tFoxaI=";
      };
      values = {
        defaultSettings.defaultDataPath = "/mnt/data/longhorn";
        defaultBackupStore = {
          backupTarget = "cifs://10.42.0.3/longhorn_backups";
          backupTargetCredentialSecret = "smb-longhorn-backups-rw";
        };
      };
    };
  };
}
