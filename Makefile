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

.PHONY: generate-nixidy-resources
generate-nixidy-resources:
	nix build .#generators.metallb
	cp result lib/generated/k8s-metallb-gen.nix

.PHONY: check-manifests
check-manifests:
	nix run .#nixidy -- build .#homelab

.PHONY: generate-manifests
generate-manifests:
	nix run .#nixidy -- switch .#homelab

.PHONY: apply-manifests
apply-manifests:
	nix run .#nixidy -- apply .#homelab

