#!/usr/bin/env bash

set -ex

# Get the backup from butters
# scp -i ~/.ssh/butters_id_ed25519 miro@butters:/var/containers/immich/backups/last/immich-latest.sql.gz immich-latest.sql.gz

# Get the superuser uri to connect to pg
# replace hostname with localhost, because we're port-forwarding
# replace * with postgres to use the postgres db
uri=$(kubectl get secret -n immich immich-database-superuser -o jsonpath='{.data.fqdn-uri}' | base64 --decode | sed "s/immich-database-rw.immich.svc.cluster.local/localhost/" | sed "s/\*$/postgres/")

# Run this in a separate terminal
# kubectl port-forward -n immich service/immich-database-rw 5432:5432

# Restore using psql, use the file from the above scp command
# https://docs.immich.app/administration/backup-and-restore/
gunzip --stdout "immich-latest.sql.gz" \
| sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
| psql $uri --echo-all # Restore Backup

# Note: Last time I've tried this, I had to run this sequence from one of the nodes using nix shell nixpkgs#postgresql_16
# because otherwise the restore from localhost would always get stuck
