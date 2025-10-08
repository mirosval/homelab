{ lib, ... }:
{
  applications.immich = {
    namespace = "immich";
    createNamespace = true;

    helm.releases.immich = {
      chart = lib.helm.downloadHelmChart {
        repo = "oci://ghcr.io/immich-app/immich-charts";
        chart = "immich";
        version = "0.9.3";
        chartHash = "sha256-UHuuu6u+UjHPgdLONZim6j+nyCINtClcAZRRJlHuaaw=";
      };

      values = {
        image.tag = "v1.139.3";
        immich = {
          persistence.library.existingClaim = "pvc-immich-rw";
        };
        redis.enabled = true;
        # This is on current master, but not yet released in 0.9.3
        # TODO: Replace redis with this
        # valkey = {
        #   enabled = true;
        #   persistence.data = {
        #     type = "pvc";
        #     storageClass = "longhorn";
        #   };
        # };
        machine-learning = {
          persistence.cache = {
            type = "pvc";
            storageClass = "longhorn";
            accessMode = "ReadWriteOnce";
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
          containers.immich-server = {
            env = lib.mkForce {
              DB_HOSTNAME_FILE.value = "/etc/secret/host";
              DB_DATABASE_NAME.value = "postgres";
              DB_USERNAME_FILE.value = "/etc/secret/user";
              DB_PASSWORD_FILE.value = "/etc/secret/password";
              IMMICH_MACHINE_LEARNING_URL.value = "http://immich-machine-learning:3003";
              REDIS_HOSTNAME.value = "immich-redis-master";
            };
            volumeMounts = [
              {
                name = "photos";
                readOnly = true;
                mountPath = "/mnt/media/rodina";
              }
              {
                name = "dburl";
                readOnly = true;
                mountPath = "/etc/secret";
              }
            ];
          };
          volumes.photos.persistentVolumeClaim.claimName = "pvc-photos-ro";
          volumes.dburl.secret.secretName = "immich-database-superuser";
        };
        immich-machine-learning.spec.template.spec = {
          containers.immich-machine-learning = {
            env = lib.mkForce {
              DB_HOSTNAME_FILE.value = "/etc/secret/host";
              DB_DATABASE_NAME.value = "postgres";
              DB_USERNAME_FILE.value = "/etc/secret/user";
              DB_PASSWORD_FILE.value = "/etc/secret/password";
              IMMICH_MACHINE_LEARNING_URL.value = "http://immich-machine-learning:3003";
              REDIS_HOSTNAME.value = "immich-redis-master";
            };
            volumeMounts = [
              {
                name = "dburl";
                readOnly = true;
                mountPath = "/etc/secret";
              }
            ];
          };
          volumes.dburl.secret.secretName = "immich-database-superuser";
        };
      };

      # fix the old redit immage
      statefulSets.immich-redis-master.spec.template.spec.containers.redis.image =
        lib.mkForce "docker.io/bitnamilegacy/redis:7.4.3-debian-12-r0";

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

      ingressRoutes.immich.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`immich.doma.lol`)";
            kind = "Rule";
            services.immich-server.port = 2283;
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
