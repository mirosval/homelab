{
  nodeRole,
  zigbeeNode,
  k3s_init,
}:

{ ... }:
{
  imports = [
    (import ./k3s {
      inherit
        nodeRole
        zigbeeNode
        k3s_init
        ;
    })
    ./dnsmasq
  ];
}

