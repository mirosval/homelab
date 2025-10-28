ENSURE_FLAKES = --extra-experimental-features "nix-command flakes"

HOMELAB_USER = miro
HOMELAB_KEY = ~/.ssh/homelab-01_id_ed25519
HOMELAB_01_IP = 10.42.0.4
HOMELAB_02_IP = 10.42.0.5
HOMELAB_03_IP = 10.42.0.6
TV_IP = 192.168.1.90

define flake_lookup
$(if $(FLAKE_$1),$(FLAKE_$1),default)
endef

guard-%:
	@ if [ "${${*}}" = "" ]; then \
                echo "Environment variable $* not set"; \
                exit 1; \
        fi

print-%  : ; @echo $*=$($*)

.PHONY: nixos-switch
nixos-switch: guard-HOST
	nixos-rebuild switch --show-trace --flake .#$(HOST)

.PHONY: nixos-switch-homelab-01
nixos-switch-homelab-01:
	NIX_SSHOPTS="-i $(HOMELAB_KEY)" nixos-rebuild \
	--flake .#homelab-01 \
	--fast \
	--use-remote-sudo \
	--build-host $(HOMELAB_USER)@$(HOMELAB_01_IP) \
	--target-host $(HOMELAB_USER)@$(HOMELAB_01_IP) \
	switch

.PHONY: nixos-switch-homelab-02
nixos-switch-homelab-02:
	NIX_SSHOPTS="-i $(HOMELAB_KEY)" nixos-rebuild \
	--flake .#homelab-02 \
	--fast \
	--use-remote-sudo \
	--build-host $(HOMELAB_USER)@$(HOMELAB_02_IP) \
	--target-host $(HOMELAB_USER)@$(HOMELAB_02_IP) \
	switch

.PHONY: nixos-switch-homelab-03
nixos-switch-homelab-03:
	NIX_SSHOPTS="-i $(HOMELAB_KEY)" nixos-rebuild \
	--flake .#homelab-03 \
	--fast \
	--use-remote-sudo \
	--build-host $(HOMELAB_USER)@$(HOMELAB_03_IP) \
	--target-host $(HOMELAB_USER)@$(HOMELAB_03_IP) \
	switch

.PHONY: check
check:
	nix flake check

.PHONY: lint
lint:
	nix run nixpkgs#statix check
	nix run nixpkgs#deadnix

.PHONY: update-secrets
update-secrets:
	nix flake lock --update-input secrets

.PHONY: check-manifests
check-manifests:
	nix run .#nixidy -- build .#homelab

.PHONY: generate-manifests
generate-manifests:
	nix run .#nixidy -- switch .#homelab

.PHONY: apply-manifests
apply-manifests:
	nix run .#nixidy -- apply .#homelab

.PHONY: clean-nixidy-resources
clean-nixidy-resources:
	rm -f lib/generated/*.nix

.PHONY: generate-nixidy-resources
generate-nixidy-resources: lib/generated/metallb.nix lib/generated/traefik.nix lib/generated/cnpg.nix lib/generated/cert-manager.nix

lib/generated/%.nix:
	nix build .#generators.$*
	install --mode 644 --no-target-directory result $@

.PHONY: generate-bootstrap
generate-bootstrap:
	nix run .#nixidy -- bootstrap .#homelab > k3s/generated_manifests/bootstrap.yaml

.PHONY: configure-kubectl
configure-kubectl:
	scp -i $(HOMELAB_KEY) $(HOMELAB_USER)@$(HOMELAB_01_IP):/etc/rancher/k3s/k3s.yaml ~/.kube/config
	sed -i 's/127.0.0.1/$(HOMELAB_01_IP)/g' ~/.kube/config

# Run this 2x and on the second time it fails with IngressRoute no matches for kind, this is ok
.PHONY: seed-argo
seed-argo: generate-manifests
	kubectl apply -f k3s/generated_manifests/argocd || true
	nix run .#nixidy -- bootstrap .#homelab > k3s/generated_manifests/bootstrap.yaml
	kubectl apply -f k3s/generated_manifests/bootstrap.yaml

.PHONY: remote-nixos-switch
remote-nixos-switch: guard-HOST
	NIX_SSHOPTS="-i $(HOMELAB_KEY)" nixos-rebuild \
		    --flake .#$(HOST) \
		    --fast \
		    --use-remote-sudo \
		    --build-host $(HOMELAB_USER)@$(HOST) \
		    --target-host $(HOMELAB_USER)@$(HOST) \
		    switch

nixos-anywhere-reset-homelab-01:
	nixos-anywhere \
		-i ~/.ssh/homelab-01_id_ed25519 \
		--copy-host-keys \
		--target-host nixos@$(HOMELAB_01_IP) \
		--flake .#homelab-01 \
		--generate-hardware-config nixos-generate-config ./hosts/homelab-01/hardware-configuration.nix \
		--disko-mode format

nixos-anywhere-reset-homelab-02:
	nixos-anywhere \
		-i ~/.ssh/homelab-01_id_ed25519 \
		--copy-host-keys \
		--target-host nixos@$(HOMELAB_02_IP) \
		--flake .#homelab-02 \
		--generate-hardware-config nixos-generate-config ./hosts/homelab-02/hardware-configuration.nix \
		--disko-mode format

nixos-anywhere-reset-homelab-03:
	nixos-anywhere \
		-i ~/.ssh/homelab-01_id_ed25519 \
		--copy-host-keys \
		--target-host nixos@$(HOMELAB_03_IP) \
		--flake .#homelab-03 \
		--generate-hardware-config nixos-generate-config ./hosts/homelab-02/hardware-configuration.nix \
		--disko-mode disko

# WARNING: This formats the disk, make sure params are correct
nixos-anywhere-init: guard-SSHPASS guard-IP guard-FLAKE
	SSHPASS=$(SSHPASS) nixos-anywhere \
		--env-password \
		-i ~/.ssh/homelab-01_id_ed25519 \
		--target-host nixos@$(IP) \
		--flake .#$(FLAKE) \
		--generate-hardware-config nixos-generate-config ./hosts/$(FLAKE)/hardware-configuration.nix

# WARNING: This formats the disk, make sure params are correct
nixos-anywhere-init-tv: guard-SSHPASS guard-IP
	SSHPASS=$(SSHPASS) nixos-anywhere \
		--env-password \
		-i ~/.ssh/homelab-01_id_ed25519 \
		--target-host nixos@$(IP) \
		--flake .#tv \
		--generate-hardware-config nixos-generate-config ./hosts/tv/hardware-configuration.nix

.PHONY: remote-nixos-switch-tv
remote-nixos-switch-tv:
	NIX_SSHOPTS="-i $(HOMELAB_KEY)" nixos-rebuild \
		    --flake .#tv \
		    --fast \
		    --use-remote-sudo \
		    --build-host $(HOMELAB_USER)@$(TV_IP) \
		    --target-host $(HOMELAB_USER)@$(TV_IP) \
		    switch

.PHONY: remote-nixos-switch
refresh-kube-config:
	scp -i $(HOMELAB_KEY) $(HOMELAB_USER)@$(HOMELAB_01_IP):/etc/rancher/k3s/k3s.yaml ~/.kube/config
	sed -i 's/127.0.0.1/$(HOMELAB_01_IP)/g' ~/.kube/config

# apk --update add bind-tools curl
.PHONY: debug-k8s
debug-k8s:
	kubectl run debug -i --rm --tty --image=alpine --restart=Never
