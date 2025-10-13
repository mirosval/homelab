{ ... }:
{
  services = {
    resolved.enable = false;
    dnsmasq = {
      enable = true;
      settings = {
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