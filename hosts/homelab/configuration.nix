{
  hostName,
  nodeRole ? "server",
  zigbeeNode ? false,
  k3s_init ? false,
}:
{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/minimal.nix")
    ../${hostName}/disk-config.nix
    ../${hostName}/hardware-configuration.nix
    (import ./services {
      inherit
        nodeRole
        zigbeeNode
        k3s_init
        hostName
        ;
    })
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Fix for immich
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_user_watches" = 524288;
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # These are for longhorn:
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };
  systemd.services.iscsid.serviceConfig = {
    PrivateMounts = "yes";
    BindPaths = "/run/current-system/sw/bin:/bin";
  };
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];

  security.sudo.wheelNeedsPassword = false;

  # Define a user account.
  users.users.miro = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      btop
    ];
    shell = pkgs.zsh;
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlwHFh+K51/iQw0CxgKKQPIBGUaVYVVrf6nxi5zkg7R miro@homelab"
      ];
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # cni
    # cni-plugin-flannel
    # cni-plugins
    dig
    # etcd
    kubectl
    neovim
    nettools
    openiscsi # needed for longhorn
    wireguard-tools # K3s Flannel
  ];

  programs.zsh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking = {
    hostName = hostName;
    networkmanager.enable = true;
    nameservers = [ "127.0.0.1" ];

    firewall.enable = true;
    firewall.allowedTCPPorts = [
      22
      80
      443
      2379 # k3s: etcd
      2380 # k3s: etcd
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      10250 # k3s: Kubelet metrics
    ];

    firewall.allowedUDPPorts = [
      51820 # Wireguard for Flannel K3s
    ];
  };

  system.stateVersion = "25.05";
}
