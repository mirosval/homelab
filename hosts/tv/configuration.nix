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
    ./disk-config.nix
    ./hardware-configuration.nix
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

  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;
  users = {
    # Define a user account.
    users.miro = {
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
    extraUsers.kodi = {
      isNormalUser = true;
      extraGroups = [
        "multimedia"
        "audio"
        "video"
        "input"
      ];
    };
    groups.multimedia = { };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    dig
    lsof
    neovim
    nettools
  ];

  programs.zsh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.xserver = {
    enable = true;
    displayManager = {
      autoLogin.user = "kodi";
      lightdm.greeter.enable = false;
    };
    desktopManager.kodi = {
      enable = true;
      package = pkgs.kodi-gbm.withPackages (
        p: with p; [
          inputstreamhelper
          inputstream-adaptive
          inputstream-ffmpegdirect
          inputstream-rtmp
          invidious
          jellyfin
          netflix
          visualization-matrix
          youtube
        ]
      );
    };
  };

  networking = {
    hostName = "tv";
    networkmanager = {
      enable = true;
      ensureProfiles.profiles = {
        "Wired connection 1" = {
          connection = {
            id = "Wired connection 1";
            type = "ethernet";
            autoconnect = true;
            autoconnect-priority = 100;
          };
        };
        "Home Wi-Fi" = {
          connection = {
            id = "Home Wi-Fi";
            type = "wifi";
            autoconnect = true;
            autoconnect-priority = 10;
          };
        };
      };

    };
    nameservers = [
      "10.42.1.250"
      "1.1.1.1"
    ];

    firewall.enable = true;
    firewall.allowedTCPPorts = [
      22
    ];
  };

  system.stateVersion = "25.05";
}
