ENSURE_FLAKES = --extra-experimental-features "nix-command flakes"

guard-%:
	@ if [ "${${*}}" = "" ]; then \
                echo "Environment variable $* not set"; \
                exit 1; \
        fi

print-%  : ; @echo $*=$($*)

.PHONY: k3s-build-manifests
k3s-build-manifests:
	nix run .#nixidy -- build .#homelab

.PHONY: k3s-generate-manifests
k3s-generate-manifests:
	nix run .#nixidy -- switch .#homelab
