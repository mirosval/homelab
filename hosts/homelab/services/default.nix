{
  nodeRole,
  zigbeeNode,
  k3s_token,
}:

{ ... }:
{
  imports = [
    (import ./k3s { inherit nodeRole zigbeeNode k3s_token; })
    ./dnsmasq
  ];
}

