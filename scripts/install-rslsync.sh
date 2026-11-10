#!/usr/bin/env bash
# Download the official rslsync binary (Resilio Sync) into ~/.local/bin.
# Checksums are pinned below; when Resilio ships a new "stable", re-pin
# or pass --i-know to skip.
set -euo pipefail

VERSION="3.1.2"
# 2026-11-05 repack: Resilio re-published the stable alias with new bytes
# under the same version label. No versioned CDN path exists for them
# (every plausible /<version>/linux/... URL 404s) and AUR still pins the
# old (3cfedd41... / cdc30638...) bytes, so these hashes were measured off
# the official CDN on CI runners — identical across two independent runs.
SHA_X64="4c4ebf8cdf992682843cd13baee307cc569615dfe1e4ba3c5061734bd7117e9b"
SHA_ARM64="cb8247c5ef6659cebd06d472e02a6fb8a7dc9aeaa584101adadad202bf328be7"

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

# The "stable" alias is a moving pointer, but since the 2026-11-05 repack
# it is the only live URL for the pinned bytes: the versioned /3.1.2/...
# CDN path is gone (404) and Resilio published no versioned path for the
# repacked artifact. Try the alias first; keep the versioned URL as a
# fallback for when per-release paths return. The sha256 gate below stays
# authoritative either way: bytes from either URL must hash to the pinned
# value before anything installs.
URL_VERSIONED="https://download-cdn.resilio.com/${VERSION}/linux/${ARCH_DIR}/0/resilio-sync_${ARCH_NAME}.tar.gz"
URL_STABLE="https://download-cdn.resilio.com/stable/linux/${ARCH_DIR}/0/resilio-sync_${ARCH_NAME}.tar.gz"
mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

downloaded=""
for url in "$URL_STABLE" "$URL_VERSIONED"; do
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
