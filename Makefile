ENSURE_FLAKES = --extra-experimental-features "nix-command flakes"

guard-%:
	@ if [ "${${*}}" = "" ]; then \
                echo "Environment variable $* not set"; \
                exit 1; \
        fi

print-%  : ; @echo $*=$($*)

.PHONY: nixos-switch
nixos-switch: guard-HOST
	nixos-rebuild switch --show-trace --flake .#$(HOST)

.PHONY: check
check:
	nix flake check

.PHONY: lint
lint:
	nix run nixpkgs#statix check
	nix run nixpkgs#deadnix

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
generate-nixidy-resources: lib/generated/metallb.nix lib/generated/traefik.nix lib/generated/cnpg.nix

lib/generated/%.nix:
	nix build .#generators.$*
	install --mode 644 --no-target-directory result $@

.PHONY: generate-bootstrap
generate-bootstrap:
	nix run .#nixidy -- bootstrap .#homelab > k3s/generated_manifests/bootstrap.yaml

debug-k8s:
	kubectl run debug -i --rm --tty --image=alpine --restart=Never
