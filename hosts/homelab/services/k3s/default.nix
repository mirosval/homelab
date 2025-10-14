{
  nodeRole,
  zigbeeNode,
  k3s_init,
}:

{ lib, config, ... }:
{
  services.k3s = {
    enable = true;
    role = nodeRole;
    clusterInit = k3s_init;
    # This can not be changed, otherwise the whole cluster is fucked
    tokenFile = config.secrets.homelab.k3s_token;
    # This may be changed if the address is not reachable or whatever
    serverAddr = if k3s_init then "" else "https://10.42.0.4:6443";
    extraFlags = lib.mkAfter (
      [
        "--write-kubeconfig-mode=644"
        "--cluster-cidr=10.44.0.0/16"
        "--service-cidr=10.45.0.0/16"
        "--flannel-iface=enp1s0"
        "--disable=traefik" # we'll manage our own
        "--disable=servicelb"
      ]
      ++ lib.optionals zigbeeNode [
        "--node-label environment=zigbee" # this node has the zigbee USB attached
      ]
      ++ lib.optionals (!k3s_init) [
        "--tls-san=homelab-01.k8s.doma.lol"
        "--tls-san=homelab-02.k8s.doma.lol"
        "--tls-san=homelab-03.k8s.doma.lol"
        "--tls-san=homelab.k8s.doma.lol"
        "--tls-san=10.42.0.4"
        "--tls-san=10.42.0.5"
        "--tls-san=10.42.0.6"
      ]
    );
  };
}

