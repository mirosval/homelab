{ ... }:
{
  # The kata-deploy Helm chart installs upstream release-tarball binaries
  # (containerd-shim-kata-v2, cloud-hypervisor, ...) which are built for a
  # standard FHS distro and fail to exec on NixOS (missing dynamic loader
  # at /lib64/ld-linux-x86-64.so.2). Instead, the actual binaries come from
  # nixpkgs' own kata-runtime + qemu_kvm packages (proper Nix store paths,
  # no FHS assumptions) — installed and wired into containerd declaratively
  # via hosts/homelab/services/k3s/default.nix. This app only defines the
  # RuntimeClass so Kubernetes knows the "kata-qemu" handler exists.
  applications.kata = {
    resources.runtimeClasses.kata-qemu = {
      handler = "kata-qemu";
      overhead.podFixed = {
        cpu = "250m";
        memory = "160Mi";
      };
    };
  };
}
