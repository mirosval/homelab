{ ... }:
{
  applications.renovate = {
    namespace = "renovate";
    createNamespace = true;
    resources = {
      cronJobs.renovate.spec = {
        schedule = "@hourly";
        concurrencyPolicy = "Forbid";
        jobTemplate.spec.template.spec = {
          restartPolicy = "Never";
          containers.renovate = {
            image = "renovate/renovate:41.135.5";
            env = [
              {
                name = "RENOVATE_CONFIG_FILE";
                value = "/opt/renovate/config.json";
              }
            ];
            envFrom = [
              {
                secretRef.name = "forgejo-renovate";
              }
            ];
            volumeMounts = [
              {
                name = "config-volume";
                mountPath = "/opt/renovate";
              }
            ];
          };
          volumes = [
            {
              name = "config-volume";
              configMap.name = "renovate-config";
            }
          ];
        };
      };

      configMaps.renovate-config.data = {
        "config.json" = builtins.toJSON {
          platform = "forgejo";
          endpoint = "https://forgejo.doma.lol";
          repositories = [
            "miro/dazzle"
            "miro/homelab"
          ];
          gitAuthor = "Renovate Bot <renovate@doma.lol>";
        };
      };
    };
  };
}
