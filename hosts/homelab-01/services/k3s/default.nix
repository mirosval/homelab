{ lib, config, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.secrets.homelab.k3s_token;
    extraFlags = lib.mkAfter [
      "--write-kubeconfig-mode=644"
      "--cluster-cidr=10.44.0.0/16"
      "--service-cidr=10.45.0.0/16"
      "--flannel-iface=enp1s0"
      "--node-label environment=zigbee" # this node has the zigbee USB attached
      "--disable=traefik" # we'll manage our own
      "--disable=servicelb"
    ];
  };
}
