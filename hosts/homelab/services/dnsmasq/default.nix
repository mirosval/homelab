{ ... }:
{
  services = {
    resolved.enable = false;
    dnsmasq = {
      enable = true;
      settings = {
        address = [
          "/homelab-01.k8s.doma.lol/10.42.0.4"
          "/homelab-02.k8s.doma.lol/10.42.0.5"
          "/homelab-03.k8s.doma.lol/10.42.0.6"
          "/homelab.k8s.doma.lol/10.42.0.4"
          "/homelab.k8s.doma.lol/10.42.0.5"
          "/homelab.k8s.doma.lol/10.42.0.6"
        ];
        server = [
          "/doma.lol/10.42.1.250"
          "1.1.1.1"
        ];
        no-resolv = true;
        cache-size = 500;
      };
    };
  };
}

