{
  nodeRole,
  zigbeeNode,
  k3s_init,
  hostName,
}:

{ lib, config, pkgs, ... }:
let
  # containerd config-v3 drop-in registering the kata-qemu RuntimeClass
  # handler. Points at nixpkgs' kata-runtime (proper Nix store paths, not
  # the FHS binaries kata-deploy would otherwise download) — see kata.nix.
  kataContainerdConfig = pkgs.writeText "kata-containerd.toml" ''
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata-qemu]
    runtime_type = "io.containerd.kata.v2"
    runtime_path = "${pkgs.kata-runtime}/bin/containerd-shim-kata-v2"
    # Don't bind-mount host /dev nodes into privileged pods (containerd's
    # default for runc) — moltis's dind container is privileged, but Kata
    # pods run in their own microVM kernel, so host devices don't apply.
    privileged_without_host_devices = true
    pod_annotations = ["io.katacontainers.*"]
    container_annotations = ["io.kubernetes.container.terminationMessage*"]

    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata-qemu.options]
    ConfigPath = "${pkgs.kata-runtime}/share/defaults/kata-containers/configuration-qemu.toml"
  '';
in
{
  # Allow k3s's containerd to access KVM and virtio devices for Kata Containers
  systemd.services.k3s.serviceConfig.DeviceAllow = [
    "/dev/kvm rwm"
    "/dev/mshv rwm"
    "/dev/kmsg rwm"
    "/dev/vhost-vsock rwm"
    "/dev/vhost-net rwm"
    "/dev/net/tun rwm"
  ];

  systemd.services.k3s.preStart = ''
    mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d
    ln -sf ${kataContainerdConfig} /var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d/kata.toml
  '';

  services.k3s = {
    enable = true;
    role = nodeRole;
    # This is used only on the first bootstrap of the cluster
    # clusterInit = k3s_init;
    clusterInit = false;
    # This can not be changed, otherwise the whole cluster is fucked
    tokenFile = config.secrets.homelab-shared.k3s_token;
    # This may be changed if the address is not reachable or whatever
    # serverAddr = if k3s_init then "" else "https://10.42.0.4:6443";
    # serverAddr = "https://10.42.0.6:6443";
    extraFlags = lib.mkAfter (
      [
        "--write-kubeconfig-mode=644"
        "--cluster-cidr=10.44.0.0/16"
        "--service-cidr=10.45.0.0/16"
        "--flannel-backend=wireguard-native"
        "--disable traefik" # we'll manage our own
        "--disable servicelb"
        # TODO: This can only be changed at node registration time
        # Otherwise: kubectl label nodes homelab-01 intel.feature.node.kubernetes.io/gpu='true'
        # "--node-label intel.feature.node.kubernetes.io/gpu='true'" # this node has an intel gpu
      ]
      ++ (
        let
          wg_ips = {
            homelab-01 = {
              # wg = "10.100.0.1";
              external = "10.42.0.4";
            };
            homelab-02 = {
              # wg = "10.100.0.2";
              external = "10.42.0.5";
            };
            homelab-03 = {
              # wg = "10.100.0.3";
              external = "10.42.0.6";
            };
          };
          external_ip = wg_ips.${hostName}.external;
        in
        [
          "--node-ip=${external_ip}"
          "--advertise-address=${external_ip}"
        ]
      )
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
