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

## Prefix pack publishing

Prefix templates are cataloged in `prefixes.json` and published as separate GitHub Release assets using tags such as `prefix-pack-2026.10`.

The repository includes helper scripts that validate the selected asset against `prefixes.json` before publishing it:

### Linux / Batocera

```bash
./scripts/publish-prefix-pack.sh 2026.10 ./default-wine-prefix-2026.10.wsquashfs.prefix
```

### Windows PowerShell

```powershell
.\scripts\publish-prefix-pack.ps1 -Version 2026.10 -Asset .\default-wine-prefix-2026.10.wsquashfs.prefix
```

Both helpers verify the expected filename, byte size and SHA-256, generate `SHA256SUMS.txt`, create the GitHub release, and upload both assets using GitHub CLI (`gh`).

The `Validate prefix catalog` GitHub Actions workflow checks the catalog structure, uniqueness, checksum format, release-tag naming and download URLs on pushes and pull requests.

## Classic Proton starter-pack update

`scripts/build-classic-proton-pack.py` packages GE-Proton10-10 and proton-EM-10.0-37-HDR from their pinned, SHA-256-verified upstream releases. It preserves Proton files and adds relative `bin`, `lib`, `lib64`, `lib32` and `share` entry points where needed for Batocera's classic Wine launcher. GE-Proton10-10 uses the toolbox's canonical installation name `GE-Proton-10-10`.

The starter selection replaces GE-Proton10-10-UMU and proton-EM-10.0-37-HDR-UMU with these classic runners, and adds GE-Proton11-7-UMU. Other runner entries are preserved. This does not uninstall runners already present on users' machines.

The `Publish classic Proton starter runners` workflow uploads only the two new archives and the updated `SHA256SUMS.txt` to the existing `starter-pack-2026.10` release, then commits the resulting catalog metadata.
