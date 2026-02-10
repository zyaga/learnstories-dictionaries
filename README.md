# LearnStories Dictionaries

Open-source dictionary files for the LearnStories language learning app.

## Current Version

**v1.0.0** (2026-02-10)

## Included Dictionaries

| Language | File | Size | Entries | Source | License |
|----------|------|------|---------|--------|---------|
| Japanese | ja.db | 77MB | 180K | JMdict (EDRDG) | CC BY-SA 4.0 |
| Chinese | zh.db | 27MB | 120K | CC-CEDICT | CC BY-SA 3.0 |
| Korean | ko.db | 8.6MB | 45K | KRDICT (NIKL) | CC BY-SA |
| Spanish | es.db | 96MB | 256K | Wiktionary | CC BY-SA |
| Italian | it.db | 74MB | 198K | Kaikki.org | CC BY-SA |
| Russian | ru.db | 9.8MB | 87K | OpenRussian | CC BY-SA 4.0 |

## Download

Download the latest release from [Releases](https://github.com/zyaga/learnstories-dictionaries/releases/latest).

## For App Integration

The app automatically downloads dictionaries from GitHub Releases using the version.json manifest:

```typescript
// Fetch version manifest
const manifest = await fetch(
  'https://raw.githubusercontent.com/zyaga/learnstories-dictionaries/main/version.json'
).then(r => r.json());

// Download URL with version and MD5 checksum
const info = manifest.dictionaries['ja'];
console.log(info.url);     // https://github.com/.../releases/download/v1.0.0/ja.db
console.log(info.md5);     // 2ea9b5103cb187e48835a46afe736bd1
console.log(info.version); // 1.0.0
```

## Development

### Creating a Release

```bash
# From the repository root
npm run release -- --type minor

# Or specify major/minor/patch
npm run release -- --type patch
npm run release -- --type major

# Dry run to test
npm run release -- --type minor --dry-run
```

This will:
1. Bump the version in version.json
2. Prompt for changelog entry
3. Calculate MD5 checksums for all dictionary files
4. Create a Git tag
5. Push the tag to GitHub
6. Create a GitHub Release
7. Upload all dictionary files as release assets
8. Verify download URLs work

### Manual Release (Fallback)

If the script fails:

1. Update version.json and CHANGELOG.md
2. Calculate MD5 checksums: `md5 -q ja/ja.db > checksums.txt`
3. Commit: `git add version.json CHANGELOG.md && git commit -m "Release v1.1.0"`
4. Tag: `git tag -a v1.1.0 -m "Release v1.1.0"`
5. Push: `git push origin main && git push origin v1.1.0`
6. Create release on GitHub UI and upload dictionary files as assets

### Requirements

- Git and Git LFS
- `jq` (JSON processor): `brew install jq`
- GitHub CLI: `brew install gh` and `gh auth login`

## Benefits of GitHub Releases

**Performance:** GitHub CDN is significantly faster than raw Git LFS URLs

**Cost:** $0/month - release assets don't count against LFS quota (previously $5/50GB)

**Reliability:** Immutable versioned releases with easy rollback capability

**Developer Experience:** One command to release, automatic version checking in app

## License

Each dictionary has its own license (see table above). The repository structure and release automation are MIT licensed.
