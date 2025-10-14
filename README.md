# Homelab

## Process for setting up new machines

### Installer 

Download and set up usb stick with nixos installer (minimal)

Run the installer on the target machine

Once logged in, set up a password for the `nixos` user, this will enable ssh.

### User for install

```shell
passwd

# Find out the IP of the target machine
ip a 
```

### nixos-anywhere setup

Then on the local machine run:

```shell
SSHPASS=<nixos password> nixos-anywhere \
    --env-password \
    -i ~/.ssh/homelab \
    --target-host nixos@<IP> \
    --flake .#homelab-01 \
    --generate-hardware-config nixos-generate-config ./hosts/homelab-01/hardware-configuration.nix
```

### Rekey secrets

Follow the rekey steps in the secrets repo (`ssh-keyscan` + `agenix --rekey`) otherwise the machine can't decrypt secrets

### Rebuild

```shell
make nixos-switch-homelab-XX
```

### Obtain kubeconfig

```shell
make refresh-kube-config
```


