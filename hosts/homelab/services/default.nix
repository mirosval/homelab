{
  nodeRole,
  zigbeeNode,
  k3s_init,
  hostName,
}:

{ ... }:
{
  imports = [
    (import ./k3s {
      inherit
        nodeRole
        zigbeeNode
        k3s_init
        hostName
        ;
    })
    ./dnsmasq
  ];
}
