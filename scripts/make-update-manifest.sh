#!/usr/bin/env bash
# Build update-manifest.json for a release and sign it (the family's
# schema-1 Ed25519 envelope; the updater contract lives in
# racket/syncpilot/updater.rkt).
#
#   scripts/make-update-manifest.sh <tag> <dist-dir> <key-der-path>
#
#   <tag>            release tag, e.g. v0.7.0 (must match the VERSION file)
#   <dist-dir>       directory containing the release artifacts, i.e. the
#                    names the release pipeline produces:
#                      syncpilot-<ver>-linux-x64.tar.gz
#                      syncpilot-<ver>-linux-arm64.tar.gz
#   <key-der-path>   Ed25519 private key, DER (OneAsymmetricKey) — the raw
#                    form of the UPDATE_ED25519_PRIVATE_KEY_B64 CI secret
#
# Emits <dist-dir>/update-manifest.json (the family-canonical feed name)
# with one targz artifact per architecture and versioned download URLs,
# plus its byte-identical twin <dist-dir>/update-stable.json — the retired
# channel-file name pre-switch installs still pull. The signing, hashing,
# schema validation, and feed format live in `raco rivet sign-manifest`;
# this wrapper owns only SyncPilot's artifact matrix and identity.
set -euo pipefail

TAG="${1:?usage: make-update-manifest.sh <tag> <dist-dir> <key-der-path>}"
DIST="${2:?usage: make-update-manifest.sh <tag> <dist-dir> <key-der-path>}"
KEY="${3:?usage: make-update-manifest.sh <tag> <dist-dir> <key-der-path>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$(cd "$DIST" && pwd)"
cd "$ROOT"

VERSION="${TAG#v}"
[[ "$VERSION" == "$(tr -d '[:space:]' < "$ROOT/VERSION")" ]] || {
  echo "error: tag $TAG does not match VERSION '$(cat "$ROOT/VERSION")'" >&2
  exit 1
}
[[ -f "$KEY" ]] || {
  echo "error: missing signing key $KEY" >&2
  exit 1
}

BUILD="$(sed -nE 's/.*\(build \. ([0-9]+)\).*/\1/p' "$ROOT/rivet.rktd" | head -n1)"
[[ -n "$BUILD" ]] || {
  echo "error: could not read build from rivet.rktd" >&2
  exit 1
}

BASE_URL="${RELEASE_ASSET_BASE_URL:-https://github.com/turlamai/syncpilot/releases/download/$TAG}"

raco rivet sign-manifest \
  --application-id site.jrtx.syncpilot \
  --version "$VERSION" \
  --build "$BUILD" \
  --channel stable \
  --base-url "$BASE_URL" \
  --key-id syncpilot-2026-10 \
  --private-key "$KEY" \
  --output "$DIST/update-manifest.json" \
  --alias "$DIST/update-stable.json" \
  --artifact "linux:x64:targz:$DIST/syncpilot-$VERSION-linux-x64.tar.gz" \
  --artifact "linux:arm64:targz:$DIST/syncpilot-$VERSION-linux-arm64.tar.gz" \
  --rollback-allowed

echo "manifest: $DIST/update-manifest.json (2 targz artifacts, key-id syncpilot-2026-10)"
