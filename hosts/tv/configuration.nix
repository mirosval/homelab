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
  boot.kernelParams = [ "i915.force_probe=46d1,i915.enable_guc=3" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  nixpkgs.config.allowUnfree = true;

  hardware = {
    enableAllFirmware = true;

    intel-gpu-tools.enable = true;
    firmware = [
      pkgs.sof-firmware
      pkgs.alsa-firmware
    ];
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

  security.rtkit.enable = true; # Enable RealtimeKit for audio purposes
  services.pulseaudio.package = pkgs.pulseaudioFull;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = false;
  };

  #
  # Bluetooth
  #
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;
  users = {
    # Define a user account.
    users.miro = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "audio"
        "video"
        "input"
      ];
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
    extraUsers.cage = {
      isNormalUser = true;
      extraGroups = [
        "audio"
        "video"
        "input"
      ];
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    alsa-utils
    dig
    lshw
    lsof
    neovim
    nettools
    pciutils
    pulseaudioFull
    sof-firmware
    alsa-firmware
    alsa-utils
  ];

  programs.zsh.enable = true;

  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
      DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
      SearchBar = "unified"; # alternative: "separate"
      ExtensionSettings = {

        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
        # uBlock Origin:
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.cage = {
    enable = true;
    user = "cage";
    program = "${pkgs.firefox}/bin/firefox -kiosk https://jellyfin.doma.lol";
  };

  # wait for network and DNS
  systemd.services."cage-tty1".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];

  # services.xserver = {
  #   enable = true;
  #   displayManager = {
  #     autoLogin.user = "kodi";
  #     lightdm.greeter.enable = false;
  #   };
  #   desktopManager.kodi = {
  #     enable = true;
  #     package = pkgs.kodi-gbm.withPackages (
  #       p: with p; [
  #         inputstreamhelper
  #         inputstream-adaptive
  #         inputstream-ffmpegdirect
  #         inputstream-rtmp
  #         invidious
  #         jellyfin
  #         netflix
  #         visualization-matrix
  #         youtube
  #       ]
  #     );
  #   };
  # };

  networking = {
    hostName = "tv";
    networkmanager = {
      enable = true;
      insertNameservers = [
        "10.42.1.250"
      ];
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
    ];

    firewall.enable = true;
    firewall.allowedTCPPorts = [
      22
    ];
  };

  system.stateVersion = "25.05";
}
