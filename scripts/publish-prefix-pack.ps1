param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Asset,
    [string]$Catalog = "prefixes.json"
)

$ErrorActionPreference = "Stop"
$Repo = "Thomson67/batocera-wine-runners"
$Tag = "prefix-pack-$Version"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLI (gh) is required." }
if (-not (Test-Path -LiteralPath $Asset -PathType Leaf)) { throw "Asset not found: $Asset" }
if (-not (Test-Path -LiteralPath $Catalog -PathType Leaf)) { throw "Catalog not found: $Catalog" }

$data = Get-Content -Raw -LiteralPath $Catalog | ConvertFrom-Json
$matches = @($data.prefixes | Where-Object { $_.version -eq $Version -and $_.default -eq $true })
if ($matches.Count -ne 1) { throw "Expected exactly one default prefix for version $Version, found $($matches.Count)." }
$entry = $matches[0]

$item = Get-Item -LiteralPath $Asset
$actualFile = $item.Name
$actualSize = $item.Length
$actualSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $Asset).Hash.ToLowerInvariant()

if ($actualFile -ne $entry.file) { throw "Filename mismatch: $actualFile != $($entry.file)" }
if ($actualSize -ne [int64]$entry.size_bytes) { throw "Size mismatch: $actualSize != $($entry.size_bytes)" }
if ($actualSha -ne $entry.sha256.ToLowerInvariant()) { throw "SHA256 mismatch: $actualSha != $($entry.sha256)" }

$sumFile = Join-Path $env:TEMP "SHA256SUMS-$Tag.txt"
$notesFile = Join-Path $env:TEMP "RELEASE-NOTES-$Tag.md"
Set-Content -LiteralPath $sumFile -Encoding ascii -Value "$actualSha  $actualFile"

$notes = @(
  "## Batocera Wine Prefix Pack $Version",
  "",
  "Wine prefix template pack for Ultimate Wine Toolbox.",
  "",
  "### Included",
  "",
  "- ``$actualFile``",
  "  - $($entry.name)",
  "  - SquashFS / Zstandard",
  "  - Size: $actualSize bytes",
  "  - SHA256: ``$actualSha``",
  "",
  "This template is intended to be downloaded and verified automatically by Ultimate Wine Toolbox."
) -join [Environment]::NewLine
Set-Content -LiteralPath $notesFile -Encoding utf8 -Value $notes

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& gh release view $Tag --repo $Repo *> $null
$releaseViewExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($releaseViewExitCode -eq 0) {
    throw "Release $Tag already exists."
}

$argsList = @(
  "release", "create", $Tag,
  $Asset,
  "$sumFile#SHA256SUMS.txt",
  "--repo", $Repo,
  "--target", "main",
  "--title", "Batocera Wine Prefix Pack $Version",
  "--notes-file", $notesFile
)
& gh @argsList
if ($LASTEXITCODE -ne 0) { throw "gh release create failed." }

Write-Host "Published $Tag successfully."
