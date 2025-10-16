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
    # packages = with pkgs; [ ];
    shell = pkgs.zsh;
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlwHFh+K51/iQw0CxgKKQPIBGUaVYVVrf6nxi5zkg7R miro@homelab"
      ];
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    bottom
    cilium-cli
    dig
    etcd
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
      51820 # Wireguard
    ];

    # nat = {
    #   enable = true;
    #   externalInterface = "enp1s0";
    #   internalInterfaces = [ "wg0" ];
    # };

    # wireguard = {
    #   enable = true;
    #   interfaces.wg0 = {
    #     ips = [
    #       (
    #         let
    #           ips = {
    #             homelab-01 = "10.100.0.1";
    #             homelab-02 = "10.100.0.2";
    #             homelab-03 = "10.100.0.3";
    #           };
    #           ip = ips.${hostName};
    #         in
    #         "${ip}/16"
    #       )
    #     ];
    #     listenPort = 51820;
    #     # # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
    #     # # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
    #     # postSetup = ''
    #     #   ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
    #     # '';
    #     #
    #     # # This undoes the above command
    #     # postShutdown = ''
    #     #   ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
    #     # '';
    #     privateKeyFile = config.secrets."${hostName}".wg_key;
    #
    #     peers = [
    #       {
    #         publicKey = "u4Nw2k1bQLoTACNNjxsAoKt5kd4j2c2zU6fnAKV+mgk=";
    #         allowedIPs = [ "10.100.0.1/32" ];
    #         endpoint = "10.42.0.4:51820";
    #       }
    #       {
    #         publicKey = "J/V0mXV62ZfEyX/5IiqyHspbuRRO3BZrPXmdY6JJ4R4=";
    #         allowedIPs = [ "10.100.0.2/32" ];
    #         endpoint = "10.42.0.5:51820";
    #       }
    #     ];
    #   };
    # };
  };

  system.stateVersion = "25.05";
}
