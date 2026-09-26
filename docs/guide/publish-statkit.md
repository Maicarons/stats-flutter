# Release statkit to pub.dev

This repository can automatically upload `packages/statkit` to [pub.dev](https://pub.dev/packages/statkit) when a new version is tagged.

## How it works

Workflow: `.github/workflows/publish-statkit.yml`

| Trigger | Action |
|---------|--------|
| Push tag `statkit-vX.Y.Z` or `vX.Y.Z` | Publish that version |
| GitHub Release published | Publish |
| `workflow_dispatch` | Manual publish |

Before publishing, CI runs `dart analyze`, `dart test`, and `dart pub publish --dry-run`.

## One-time setup (required)

1. Open [pub.dev → statkit → Admin](https://pub.dev/packages/statkit/admin)
2. Enable **Automated publishing from GitHub Actions**
3. Set repository to `Maicarons/stats-flutter`
4. Optional: tag pattern `statkit-v` (or leave `v`)

Without this, `dart pub publish` from CI cannot authenticate via OIDC.

### Fallback secret (optional)

If you prefer credentials over OIDC:

```bash
dart pub token add https://pub.dev
# or copy credentials.json from ~/.config/dart/
```

Add GitHub secret `PUB_CREDENTIALS` with that JSON.

## Release a new version

```bash
# 1. Bump version in packages/statkit/pubspec.yaml
# 2. Update packages/statkit/CHANGELOG.md
# 3. Commit & tag
cd packages/statkit   # from repo root:
# edit pubspec.yaml version: x.y.z
git add packages/statkit
git commit -m "chore(statkit): release x.y.z"
git tag statkit-x.y.z
git push origin main statkit-x.y.z
```

CI will verify tag ↔ pubspec version, run tests, then upload to pub.dev.

## Notes

- Publishing the **same version twice** fails on pub.dev — always bump `version`.
- Tag version must match `packages/statkit/pubspec.yaml` → `version:`.
- `v*` tags also work if they match the statkit version (e.g. `v0.1.0`).
