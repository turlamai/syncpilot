#!/usr/bin/env bash
# Download the official rslsync binary (Resilio Sync) into ~/.local/bin.
# Checksums are pinned from the AUR rslsync PKGBUILD for the version below;
# when Resilio ships a new "stable", re-pin or pass --i-know to skip.
set -euo pipefail

VERSION="3.1.2"
SHA_X64="3cfedd41b3d21e2ae5fae58ca2114704d1ea4e4bab896796323c4a15c570f0f0"
SHA_ARM64="cdc30638d4a1909fb16685d25924216af70c2758160ffa74822d371f574fe136"

DEST="${RSLSYNC_DEST:-$HOME/.local/bin}"
SKIP_CHECKSUM=0
for arg in "$@"; do
  case "$arg" in
    --i-know) SKIP_CHECKSUM=1 ;;
    *) echo "usage: $0 [--i-know]"; exit 2 ;;
  esac
done

case "$(uname -m)" in
  x86_64) ARCH_DIR="x64"; ARCH_NAME="x64"; EXPECTED="$SHA_X64" ;;
  aarch64|arm64) ARCH_DIR="arm64"; ARCH_NAME="arm64"; EXPECTED="$SHA_ARM64" ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

# The versioned CDN URL is the official per-release form; the "stable"
# alias is a moving pointer. On 2026-11-10 the alias drifted past v3.1.2
# under CI and broke the integration smoke with a checksum mismatch, so
# this script pins the versioned URL first and keeps the alias only as a
# fallback. The sha256 gate below stays authoritative either way: bytes
# from either URL must hash to the pinned value before anything installs.
URL_VERSIONED="https://download-cdn.resilio.com/${VERSION}/linux/${ARCH_DIR}/0/resilio-sync_${ARCH_NAME}.tar.gz"
URL_STABLE="https://download-cdn.resilio.com/stable/linux/${ARCH_DIR}/0/resilio-sync_${ARCH_NAME}.tar.gz"
mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

downloaded=""
for url in "$URL_VERSIONED" "$URL_STABLE"; do
  echo "downloading $url"
  if curl -fsSL --max-time 300 -o "$TMP/rslsync.tar.gz" "$url"; then
    downloaded="$url"
    break
  fi
  echo "download failed, trying next URL" >&2
done
[ -n "$downloaded" ] || { echo "all download URLs failed" >&2; exit 1; }

ACTUAL="$(sha256sum "$TMP/rslsync.tar.gz" | cut -d' ' -f1)"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  # Evidence, not just a verdict: a CDN block/error page (HTTP 200, HTML)
  # and a genuine upstream re-pack produce the same single-line mismatch.
  echo "checksum mismatch:" >&2
  echo "  source:               $downloaded" >&2
  echo "  expected (v$VERSION): $EXPECTED" >&2
  echo "  actual:               $ACTUAL" >&2
  echo "  size: $(wc -c < "$TMP/rslsync.tar.gz") bytes; file: $(file -b "$TMP/rslsync.tar.gz")" >&2
  echo "  head: $(head -c 64 "$TMP/rslsync.tar.gz" | od -An -c | tr -s ' ' | head -2)" >&2
  if [ "$SKIP_CHECKSUM" != "1" ]; then
    echo "stable may have moved past v$VERSION (or the CDN served this network an error page). Re-pin in this script, or re-run with --i-know to install anyway." >&2
    exit 1
  fi
  echo "installing anyway (--i-know)." >&2
else
  echo "checksum ok ($ACTUAL)"
fi

tar xzf "$TMP/rslsync.tar.gz" -C "$TMP"
install -m 755 "$TMP/rslsync" "$DEST/rslsync"
echo "installed: $DEST/rslsync"
"$DEST/rslsync" --help 2>&1 | head -2 || true
