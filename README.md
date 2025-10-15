# Homelab

## Setting up new machines

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

## Bootstrapping The Cluster

### Install argo

```shell
# In case manifests are out of date
make generate-manifests

kubectl apply -f k3s/generated_manifests/argocd/Namespace-argocd.yaml
# Remove this, because at this point there is no traefik crd
rm k3s/generated_manifests/argocd/IngressRoute-argocd.yaml
kubectl apply -f k3s/generated_manifests/argocd

# There is probably going to be a failure applying some resources, 
# e.g. the IngressRoute, this can be ignored at this point. 
# Check install with:
kubectl get po -n argocd
```

### Bootstrap Argo

```shell
make generate-bootstrap
kubectl apply -f k3s/generated_manifests/bootstrap.yaml
```

Look at argo
```shell
kubectl port-forward svc/argocd-server -n argocd 8080:443
open http://localhost:8080
```
