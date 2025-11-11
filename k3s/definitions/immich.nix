{ lib, ... }:
{
  applications.immich = {
    namespace = "immich";
    createNamespace = true;

    helm.releases.immich = {
      chart = lib.helm.downloadHelmChart {
        repo = "oci://ghcr.io/immich-app/immich-charts";
        chart = "immich";
        version = "0.10.1";
        chartHash = "sha256-OtwfVn76iz2P7Mu95GaPLChkjT4OKiNBKllJx2QVTwo=";
      };

      values = {
        controllers.main.containers.main = {
          image.tag = "v2.2.3";
          env = {
            DB_HOSTNAME_FILE = "/etc/secret/host";
            DB_DATABASE_NAME = "postgres";
            DB_USERNAME_FILE = "/etc/secret/user";
            DB_PASSWORD_FILE = "/etc/secret/password";
            IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
            REDIS_HOSTNAME = "immich-valkey";
          };
        };
        immich = {
          persistence = {
            library = {
              type = "persistentVolumeClaim";
              existingClaim = "pvc-immich-rw";
              accessMode = "ReadWriteOnce";
            };
          };
        };
        valkey = {
          enabled = true;
          persistence.data = {
            type = "persistentVolumeClaim";
            storageClass = "longhorn";
          };
        };
        server = {
          controllers.main = {
            replicas = 3;
            containers.main.resources.limits."gpu.intel.com/i915" = "1000m";
          };
          persistence = {
            photos = {
              type = "persistentVolumeClaim";
              accessMode = "ReadOnly";
              existingClaim = "pvc-photos-ro";
              advancedMounts.main.main = [
                {
                  readOnly = true;
                  path = "/mnt/media/rodina";
                }
              ];
            };
            dburl = {
              type = "secret";
              advancedMounts.main.main = [
                {
                  readOnly = true;
                  path = "/etc/secret";
                }
              ];
            };
          };
        };
        machine-learning = {
          controllers.main = {
            replicas = 3;
            containers.main.resources.limits."gpu.intel.com/i915" = "1000m";
          };
          persistence = {
            cache = {
              type = "emptyDir";
              accessMode = "ReadWriteMany";
            };
            dburl = {
              type = "secret";
              advancedMounts.main.main = [
                {
                  readOnly = true;
                  path = "/etc/secret";
                }
              ];
            };
          };
        };
      };
    };

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
      # Patch generated resources
      deployments = {
        immich-server.spec.template.spec = {
          volumes.dburl.secret.secretName = lib.mkForce "immich-database-superuser";
        };
        immich-machine-learning.spec = {
          template.spec = {
            volumes.dburl.secret.secretName = lib.mkForce "immich-database-superuser";
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

      persistentVolumeClaims.pvc-photos-ro.spec = {
        accessModes = [ "ReadOnlyMany" ];
        volumeName = "pv-photos-ro";
        storageClassName = "smb";
        resources.requests.storage = "10Gi";
      };

      persistentVolumes.pv-immich-rw = {
        metadata.annotations = {
          "pv.kubernetes.io/provisioned-by" = "smb.csi.k8s.io";
        };
        spec = {
          capacity.storage = "2Ti";
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "smb";
          mountOptions = [
            "dir_mode=0777"
            "file_mode=0444"
          ];
          csi = {
            driver = "smb.csi.k8s.io";
            volumeHandle = "10.42.0.3/smb_immich_rw";
            volumeAttributes.source = "//10.42.0.3/photos/immich";
            nodeStageSecretRef = {
              name = "smb-immich-rw";
              namespace = "immich";
            };
          };
        };
      };

      persistentVolumeClaims.pvc-immich-rw.spec = {
        accessModes = [ "ReadWriteOnce" ];
        volumeName = "pv-immich-rw";
        storageClassName = "smb";
        resources.requests.storage = "2Ti";
      };

      middlewares.immich-limit.spec.buffering = {
        maxRequestBodyBytes = 10000000000; # 10GB
      };
      ingressRoutes.immich.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`immich.doma.lol`)";
            kind = "Rule";
            services.immich-server.port = 2283;
          }
        ];
      };

      ingresses.immich.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "immich.doma.lol";
          }
        ];
      };
    };
  };
}
