#!/usr/bin/env bash
# TEMPORARY CDN probe for the rslsync re-pin decision (continues 5016413 +
# 3b8ac66). Read-only evidence gathering — download, hash, strings; the
# binary is never executed and nothing is installed. Remove with the re-pin.
set -uo pipefail
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== versioned URL probes (runner network) =="
for v in 3.1.2 3.1.3 3.1.4 3.2.0 3.2.1 3.2.2; do
  url="https://download-cdn.resilio.com/$v/linux/x64/0/resilio-sync_x64.tar.gz"
  code="$(curl -s -o /dev/null --max-time 30 -w '%{http_code}' "$url" || echo ERR)"
  echo "  $v -> HTTP $code"
done

echo "== resilio apt repo (independent publication channel) =="
apt_url="https://linux-packages.resilio.com/resilio-sync/dists/resilio-sync/binary-amd64/Packages"
if curl -fsSL --max-time 30 -o "$TMP/Packages" "$apt_url"; then
  grep -E "^(Version|Filename|SHA256):" "$TMP/Packages" | head -9
else
  echo "  apt repo unreachable from runner"
fi

echo "== stable alias x64 =="
x64="https://download-cdn.resilio.com/stable/linux/x64/0/resilio-sync_x64.tar.gz"
if curl -fsSL --max-time 300 -o "$TMP/x64.tar.gz" "$x64"; then
  echo "  sha256: $(sha256sum "$TMP/x64.tar.gz" | cut -d' ' -f1)"
  echo "  size:   $(wc -c < "$TMP/x64.tar.gz") bytes"
  tar xzf "$TMP/x64.tar.gz" -C "$TMP" || echo "  tar failed"
  if [ -f "$TMP/rslsync" ]; then
    echo "  binary: $(file -b "$TMP/rslsync")"
    echo "  banner strings:"
    strings -a "$TMP/rslsync" | grep -E "Resilio Sync [0-9]" | head -3 | sed 's/^/    /'
    echo "  version-like strings:"
    strings -a "$TMP/rslsync" | grep -Eo "\b3\.[0-9]+\.[0-9]+(\.[0-9]+)?\b" | sort -u | head -8 | sed 's/^/    /'
  fi
else
  echo "  x64 download failed"
fi

echo "== stable alias arm64 =="
arm="https://download-cdn.resilio.com/stable/linux/arm64/0/resilio-sync_arm64.tar.gz"
if curl -fsSL --max-time 300 -o "$TMP/arm64.tar.gz" "$arm"; then
  echo "  sha256: $(sha256sum "$TMP/arm64.tar.gz" | cut -d' ' -f1)"
  echo "  size:   $(wc -c < "$TMP/arm64.tar.gz") bytes"
  tar tzf "$TMP/arm64.tar.gz" | head -3 | sed 's/^/    contains: /'
else
  echo "  arm64 download failed"
fi
