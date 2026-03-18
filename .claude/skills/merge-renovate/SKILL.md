---
name: merge-renovate
description: Accept a Renovate bot PR from Forgejo, update the homelab manifests, and push to both remotes. Use when the user wants to merge a pending Renovate update.
---

Merge a Renovate bot PR from Forgejo and regenerate the homelab Kubernetes manifests.

## Steps

### 1. Check repo is clean

Run `jj status` and verify the working copy has no uncommitted changes. If there are pending changes, stop and ask the user how to proceed.

### 2. List open Renovate PRs

Fetch open PRs from the Forgejo API:
```
curl -s -H "Authorization: token $CLAUDE_FORGEJO_API_TOKEN" \
  "https://forgejo.doma.lol/api/v1/repos/miro/homelab/pulls?state=open&limit=50"
```

Filter to only PRs where the head branch starts with `renovate/`. Display the list to the user (number, title, branch).

### 3. Choose a PR

If $ARGUMENTS specifies a PR number, use that. Otherwise pick one at random from the list and tell the user which one was chosen.

### 4. Merge the PR via Forgejo API

```
curl -s -X POST \
  -H "Authorization: token $CLAUDE_FORGEJO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Do": "merge"}' \
  "https://forgejo.doma.lol/api/v1/repos/miro/homelab/pulls/<PR_NUMBER>/merge"
```

### 5. Fetch from forgejo remote

```
jj git fetch --remote forgejo
```

### 6. Create a new empty commit on top of main@forgejo

```
jj new main@forgejo
```

### 7. Regenerate manifests

Run `make generate-manifests`. If it fails with a hash mismatch, extract the `got:` hash from the error output and update the `chartHash` field in the relevant `k3s/definitions/*.nix` file, then re-run `make generate-manifests`.

### 8. Review the diff

Run `jj diff` and carefully inspect the changes. **Stop and ask the user how to proceed if any of the following are true:**
- New Kubernetes resource kinds are being added (new Deployments, StatefulSets, CRDs, ClusterRoles, etc.)
- Existing resources are being deleted
- There are changes to RBAC, network policies, or storage classes
- The diff is large (more than ~50 lines changed across manifests)
- There are changes to anything other than version labels, image tags, and chart checksums
- Anything else that looks non-trivial or surprising

For a routine Helm chart bump, you expect to see only: chart label version bumps, image tag updates, and checksum annotation changes.

### 9. Commit

```
jj commit -m "<descriptive message, e.g. 'update pihole to v2.35.0'>"
```

### 10. Sync both remotes

The repo has two remotes (`forgejo` and `origin`/GitHub) that must stay in sync.

Check the current state with `jj bookmark list main`. If main@forgejo and main@origin have diverged, create a merge commit combining both:

```
jj new <forgejo-tip> <other-tip> -m "<message>"
```

Then set both bookmarks to the new commit:
```
jj b set main -r@
jj b set forgejo -r@
```

Push to both remotes:
```
jj git push --remote forgejo --bookmark main
jj git push --remote origin --bookmark main
```

Confirm both pushes moved forward (not sideways) — if one was sideways, the remotes were out of sync and a merge commit was needed.
