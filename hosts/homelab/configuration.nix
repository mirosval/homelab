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
let
  host_map = {
    homelab-01.ip = "10.42.0.4";
    homelab-02.ip = "10.42.0.5";
    homelab-03.ip = "10.42.0.6";
  };
  current_host = host_map.${hostName};
in
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

  boot.kernelParams = [ "i915.force_probe=46d1,i915.enable_guc=3" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Fix for immich
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_user_watches" = 524288;
  };

  hardware = {
    enableAllFirmware = true;
    intel-gpu-tools.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        intel-compute-runtime
        intel-ocl
        vpl-gpu-rt
      ];
    };
    cpu.intel.updateMicrocode = true;
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

  nixpkgs.config.allowUnfree = true;

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
    lsof
    # etcd
    kubectl
    neovim
    nettools
    openiscsi # needed for longhorn
    wireguard-tools # K3s Flannel
  ];

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  programs.zsh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking = {
    hostName = hostName;
    networkmanager = {
      enable = true;
      ensureProfiles = {
        profiles = {
          enp1s0 = {
            connection = {
              id = "enp1s0";
              type = "ethernet";
              uuid = "16864a5c-b065-38f7-9b70-263c0410fc25";
              interface-name = "enp1s0";
              autoconnect = true;
              mdns = 2;
            };
            ipv4 = {
              method = "manual";
              addresses = "${current_host.ip}/23";
              gateway = "10.42.0.1";
              dns = "127.0.0.1";
            };
            ipv6.method = "disabled";
          };
          wifi = {
            connection = {
              id = "wifi";
              type = "wifi";
              uuid = "07b10837-7efd-3edd-959c-2d40bc971679";
              autoconnect = true;
            };
            ipv4.method = "auto";
            wifi = {
              mode = "infrastructure";
              ssid = "$WIFI_NAME";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PSK";
            };
          };
        };
        environmentFiles = [ config.secrets.homelab.wifi ];
      };

    };
    nameservers = [ "127.0.0.1" ];

    firewall.enable = true;
    firewall.allowedTCPPorts = [
      22
      80
      443
      2379 # k3s: etcd
      2380 # k3s: etcd
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      7946 # MetalLB
      10250 # k3s: Kubelet metrics
    ];

    firewall.allowedUDPPorts = [
      7946 # MetalLB
      51820 # Wireguard for Flannel K3s
    ];
  };

  system.stateVersion = "25.05";
}
