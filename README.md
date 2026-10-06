# Batocera Wine Runners

Curated Wine/Proton runner catalog for Batocera, maintained for use with the **Thomsonito Batocera Wine Toolbox**.

## Purpose

This repository stores the runner catalog and Starter Pack manifests. Large runner archives are distributed through GitHub Releases instead of being committed to Git history.

## Catalog

- `runners.json` — all available runners and their metadata.
- `starter-pack.json` — runners selected for the Thomsonito Runner Starter Pack.
- `prefixes.json` — downloadable Wine prefix templates used by Ultimate Wine Toolbox.

## Installation target

Runners are installed by the toolbox into:

```text
/userdata/system/wine/custom/
```

## Distribution

Runner archives and Wine prefix templates are published as GitHub Release assets. Each catalog entry references a release tag and SHA-256 checksum so the toolbox can verify downloads before installation.

Prefix templates are installed by Ultimate Wine Toolbox under:

```text
/userdata/system/ultimate-wine-toolbox/templates/
```

## Status

Initial catalog structure. Release assets and checksums will be added next.
