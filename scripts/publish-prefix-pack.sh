#!/usr/bin/env bash
set -euo pipefail

REPO="Thomson67/batocera-wine-runners"
VERSION="${1:-}"
ASSET="${2:-}"
CATALOG="${3:-prefixes.json}"

if [[ -z "$VERSION" || -z "$ASSET" ]]; then
  echo "Usage: $0 <version> <path-to-prefix-asset> [prefixes.json]" >&2
  echo "Example: $0 2026.10 ./default-wine-prefix-2026.10.wsquashfs.prefix" >&2
  exit 2
fi

for cmd in gh python3 sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done

[[ -f "$ASSET" ]] || { echo "Asset not found: $ASSET" >&2; exit 1; }
[[ -f "$CATALOG" ]] || { echo "Catalog not found: $CATALOG" >&2; exit 1; }
TAG="prefix-pack-$VERSION"

mapfile -t META < <(python3 - "$CATALOG" "$VERSION" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
version=sys.argv[2]
matches=[x for x in data.get('prefixes', []) if x.get('version')==version and x.get('default')]
if len(matches)!=1:
    raise SystemExit(f'Expected exactly one default prefix for version {version}, found {len(matches)}')
x=matches[0]
print(x['file'])
print(x['sha256'])
print(x['size_bytes'])
print(x['name'])
PY
)

EXPECTED_FILE="${META[0]}"
EXPECTED_SHA="${META[1]}"
EXPECTED_SIZE="${META[2]}"
DISPLAY_NAME="${META[3]}"
ACTUAL_FILE="$(basename "$ASSET")"
ACTUAL_SHA="$(sha256sum "$ASSET" | awk '{print $1}')"
ACTUAL_SIZE="$(wc -c < "$ASSET" | tr -d '[:space:]')"

[[ "$ACTUAL_FILE" == "$EXPECTED_FILE" ]] || { echo "Filename mismatch: $ACTUAL_FILE != $EXPECTED_FILE" >&2; exit 1; }
[[ "$ACTUAL_SHA" == "$EXPECTED_SHA" ]] || { echo "SHA256 mismatch: $ACTUAL_SHA != $EXPECTED_SHA" >&2; exit 1; }
[[ "$ACTUAL_SIZE" == "$EXPECTED_SIZE" ]] || { echo "Size mismatch: $ACTUAL_SIZE != $EXPECTED_SIZE" >&2; exit 1; }

SUMS="$(mktemp)"
NOTES="$(mktemp)"
trap 'rm -f "$SUMS" "$NOTES"' EXIT
printf '%s  %s\n' "$ACTUAL_SHA" "$ACTUAL_FILE" > "$SUMS"

cat > "$NOTES" <<EOF
## Batocera Wine Prefix Pack $VERSION

Wine prefix template pack for Ultimate Wine Toolbox.

### Included

- `$ACTUAL_FILE`
  - $DISPLAY_NAME
  - SquashFS / Zstandard
  - Size: $ACTUAL_SIZE bytes
  - SHA256: `$ACTUAL_SHA`

This template is intended to be downloaded and verified automatically by Ultimate Wine Toolbox.
EOF

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists." >&2
  exit 1
fi

gh release create "$TAG" "$ASSET" "$SUMS#SHA256SUMS.txt" \
  --repo "$REPO" \
  --target main \
  --title "Batocera Wine Prefix Pack $VERSION" \
  --notes-file "$NOTES"

echo "Published $TAG successfully."
