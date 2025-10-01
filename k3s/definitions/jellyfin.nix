{ lib, ... }:
{
  applications.jellyfin = {
    namespace = "jellyfin";
    createNamespace = true;
    helm.releases.jellyfin = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://jellyfin.github.io/jellyfin-helm";
        chart = "jellyfin";
        version = "2.3.0";
        chartHash = "sha256-uqdSUZ034DXIGsEyJEh7XXmy+Ru6ovrhw8SOf4ZqKBQ=";
      };

      values = {

        persistence = {
          config = {
            storageClass = "longhorn";
          };
          media = {
            accessMode = "ReadOnly";
            existingClaim = "pvc-movies-ro";
          };
        };
      };
    };

    resources = {

      persistentVolumes.pv-movies-ro = {
        metadata.annotations = {
          "pv.kubernetes.io/provisioned-by" = "smb.csi.k8s.io";
        };
        spec = {
          capacity.storage = "10Gi";
          accessModes = [ "ReadOnlyMany" ];
          storageClassName = "smb";
          mountOptions = [
            "dir_mode=0777"
            "file_mode=0444"
          ];
          csi = {
            driver = "smb.csi.k8s.io";
            volumeHandle = "10.42.0.3/smb_movies_ro";
            volumeAttributes.source = "//10.42.0.3/movies";
            nodeStageSecretRef = {
              name = "smb-movies-ro";
              namespace = "jellyfin";
            };
          };
        };
      };

      roles.csi-smb-secret-access.rules = [
        {
          apiGroups = [ "" ];
          resources = [ "secrets" ];
          verbs = [
            "get"
            "list"
          ];
        }
      ];

      roleBindings.csi-smb-secret-access-binding = {
        subjects = [
          {
            kind = "ServiceAccount";
            name = "csi-smb-node-sa";
            namespace = "csi-driver-smb";
          }
        ];
        roleRef = {
          kind = "Role";
          name = "csi-smb-secret-access";
          apiGroup = "rbac.authorization.k8s.io";
        };
      };

      persistentVolumeClaims.pvc-movies-ro.spec = {
        accessModes = [ "ReadOnlyMany" ];
        volumeName = "pv-movies-ro";
        storageClassName = "smb";
        resources.requests.storage = "10Gi";
      };

      ingressRoutes.jellyfin.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`jellyfin.doma.lol`)";
            kind = "Rule";
            services.jellyfin.port = 8096;
          }
        ];
        tls = {
          certResolver = "letsencrypt";
          domains = [
            {
              main = "doma.lol";
              sans = [ "*.doma.lol" ];
            }
          ];
        };
      };

      ingresses.jellyfin.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "jellyfin.doma.lol";
          }
        ];
      };
    };
  };
}
