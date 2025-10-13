{ hostName }:

{ ... }:
{
  networking = {
    hostName = hostName;
    networkmanager.enable = true;
    nameservers = [ "127.0.0.1" ];

    firewall.enable = true;
    firewall.allowedTCPPorts = [
      22
      80
      443
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    ];
  };
}