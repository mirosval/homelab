{ lib, ... }:
{
  applications.longhorn = {
    namespace = "longhorn";
    createNamespace = true;
    helm.releases.longhorn = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.longhorn.io";
        chart = "longhorn";
        version = "1.9.1";
        chartHash = "sha256-jDI7vHl0QNAgFEgAdPf8HoG7OcnRED3QNMSN+tFoxaI=";
      };
      values = {
        defaultSettings.defaultDataPath = "/mnt/data/longhorn";
        defaultBackupStore = {
          backupTarget = "cifs://10.42.0.3/longhorn_backups";
          backupTargetCredentialSecret = "smb-longhorn-backups-rw";
        };
        metrics.serviceMonitor.enabled = true;
      };
    };

    resources = {
      middlewares.longhorn-auth.spec.basicAuth.secret = "longhorn-auth";

      ingressRoutes.longhorn.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`longhorn.doma.lol`)";
            kind = "Rule";
            middlewares = [ { name = "longhorn-auth"; } ];
            services.longhorn-frontend.port = 80;
          }
        ];
      };

      ingresses.longhorn.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "longhorn.doma.lol";
          }
        ];
      };
    };

  };
}
