# Publish statkit to pub.dev

`packages/statkit` is published automatically via **pub.dev OIDC** + the official Dart reusable workflow.

Workflow file (required name): **`.github/workflows/publish.yml`**

```yaml
name: Publish to pub.dev

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+*'

jobs:
  publish:
    permissions:
      id-token: write
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
    with:
      working-directory: packages/statkit
```

## Prerequisites (already done)

On [pub.dev/packages/statkit/admin](https://pub.dev/packages/statkit/admin):

- Enable **Automated publishing from GitHub Actions**
- Repository: `Maicarons/stats-flutter`

## How to release

1. Bump `version` in `packages/statkit/pubspec.yaml` (e.g. `0.2.0`)
2. Update `packages/statkit/CHANGELOG.md`
3. Commit and push a matching **v** tag:

```bash
git add packages/statkit
git commit -m "chore(statkit): release 0.2.0"
git tag v0.2.0
git push origin main v0.2.0
```

The tag **must** match the package `version` (`v` + version).  
pub.dev rejects duplicate versions — always bump `version` first.

## Notes

- Only packages under `packages/statkit` are uploaded (see `working-directory`).
- If you also tag app releases like `app-v1.0.0`, those tags do **not** trigger publish (pattern is `vX.Y.Z`).
