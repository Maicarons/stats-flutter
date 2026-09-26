from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\README.md")
t = p.read_text(encoding="utf-8")
if "publish-statkit" not in t:
    block = """## Publishing statkit

Tag a release and GitHub Actions publishes `packages/statkit` to pub.dev automatically.

```bash
# bump version in packages/statkit/pubspec.yaml + CHANGELOG
git tag statkit-0.2.0
git push origin main statkit-0.2.0
```

Workflow: `.github/workflows/publish-statkit.yml` · Guide: [docs/guide/publish-statkit.md](docs/guide/publish-statkit.md)

One-time: enable **Automated publishing from GitHub Actions** on [pub.dev/packages/statkit/admin](https://pub.dev/packages/statkit/admin).

## License"""
    t = t.replace("## License", block, 1)
    p.write_text(t, encoding="utf-8")
    print("readme")
else:
    print("readme exists")

p = Path(r"F:\workspace\stats-flutter\docs\.vitepress\config.mts")
t = p.read_text(encoding="utf-8")
if "publish-statkit" not in t:
    t = t.replace(
        "{ text: 'statkit API', link: '/api/statkit' },",
        "{ text: 'statkit API', link: '/api/statkit' },\n              { text: '发布到 pub.dev', link: '/guide/publish-statkit' },",
        1,
    )
    t = t.replace(
        "items: [{ text: 'statkit API', link: '/en/api/statkit' }],",
        "items: [\n              { text: 'statkit API', link: '/en/api/statkit' },\n              { text: 'Publish to pub.dev', link: '/en/guide/publish-statkit' },\n            ],",
        1,
    )
    p.write_text(t, encoding="utf-8")
    print("config")
else:
    print("config exists")

print("done")
