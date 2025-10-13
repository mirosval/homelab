{ nodeRole, zigbeeNode }:

{ ... }:
{
  imports = [
    (import ./k3s { inherit nodeRole zigbeeNode; })
    ./dnsmasq
  ];
}