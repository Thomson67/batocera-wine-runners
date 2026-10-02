# Batocera Wine Runners

Curated Wine/Proton runner catalog for Batocera, maintained for use with the **Thomsonito Batocera Wine Toolbox**.

## Purpose

This repository stores the runner catalog and Starter Pack manifests. Large runner archives are distributed through GitHub Releases instead of being committed to Git history.

## Catalog

- `runners.json` — all available runners and their metadata.
- `starter-pack.json` — runners selected for the Thomsonito Runner Starter Pack.

## Installation target

Runners are installed by the toolbox into:

```text
/userdata/system/wine/custom/
```

## Distribution

Runner archives are published as GitHub Release assets. Each catalog entry can reference a release tag and a SHA-256 checksum so the toolbox can verify downloads before installation.

## Status

Initial catalog structure. Release assets and checksums will be added next.
