{ ... }:
{
  applications.immich = {
    namespace = "immich";
    createNamespace = true;

    resources = {
      # PG Cluster
      clusters.immich-database.spec = {
        instances = 1;
        storage = {
          size = "10Gi";
          storageClass = "longhorn";
        };
        imageName = "ghcr.io/tensorchord/cloudnative-vectorchord:16.9-0.4.3";
        postgresql.shared_preload_libraries = [ "vchord.so" ];
        bootstrap.initdb.postInitApplicationSQL = [
          "create extension vchord cascade;"
          "create extension earthdistance cascade;"
        ];
        enableSuperuserAccess = true;
      };

      persistentVolumes.pv-photos-ro = {
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
            volumeHandle = "10.42.0.3/smb_photos_ro";
            volumeAttributes.source = "//10.42.0.3/photos";
            nodeStageSecretRef = {
              name = "smb-photos-ro";
              namespace = "immich";
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

      persistentVolumeClaims.pvc-photos-ro.spec = {
        accessModes = [ "ReadOnlyMany" ];
        volumeName = "pv-photos-ro";
        storageClassName = "smb";
        resources.requests.storage = "10Gi";
      };
    };
  };
}
