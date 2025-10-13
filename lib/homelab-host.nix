{ hostName, nodeRole ? "server", zigbeeNode ? false }:

{ lib, pkgs, config, ... }:

{
  imports = [
    (../hosts + "/${hostName}/hardware-configuration.nix")
    (import ./networking.nix { inherit hostName; })
  ] ++ lib.optionals (nodeRole != "none") [
    (import ./services { inherit nodeRole zigbeeNode; })
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
      tree
      neovim
      git
    ];
    shell = pkgs.zsh;
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlwHFh+K51/iQw0CxgKKQPIBGUaVYVVrf6nxi5zkg7R miro@homelab-01"
      ];
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    bottom
    gh
    git
    gnumake
    kubectl
    kubernetes
    neovim
    nettools
    openiscsi # needed for longhorn
  ];

  programs.zsh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

}