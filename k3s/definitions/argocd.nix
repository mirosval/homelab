{ lib, ... }:
{
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;
    helm.releases.argocd = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://argoproj.github.io/argo-helm/";
        chart = "argo-cd";
        version = "9.1.1";
        chartHash = "sha256-Wt/7p8pnI6FJENFg4vDMVtsqTFQ9rKcjm/ncdO+4G24=";
      };
      values = {
        configs.params."server.insecure" = true; # TLS terminated at traefik
        configs.secret.argocdServerAdminPassword = "$2y$10$afCoYAVuSdaC4k3P4lhUcezO4HCLVzCLBaYu03tGi.9WP7Lt47gcC";
      };
    };

    resources = {
      ingressRoutes.argocd.spec = {
        entryPoints = [ "websecure" ];
        routes = [
          {
            match = "Host(`argo.doma.lol`)";
            kind = "Rule";
            services.argocd-server.port = 80;
            priority = 10;
          }
          {
            match = "Host(`argo.doma.lol`) && Header(`Content-Type`, `application/grpc`)";
            kind = "Rule";
            services.argocd-server = {
              port = 80;
              scheme = "h2c";
            };
            priority = 11;
          }

        ];
      };

      ingresses.argocd.spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "argo.doma.lol";
          }
        ];
      };
    };
  };
}
