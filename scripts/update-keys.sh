#!/usr/bin/env bash
# Generate the Ed25519 keypair that signs SyncPilot update manifests.
#
#   scripts/update-keys.sh [private-key-path]
#
# Default private key location: ~/.syncpilot/update-signing-key.pem —
# OUTSIDE the repository. `raco rivet update-keys` prints every embedding
# form: the private DER base64 for UPDATE_ED25519_PRIVATE_KEY_B64, the SPKI
# base64 for racket/syncpilot/version.rkt, and the raw/base64 hex variants.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PATH="${1:-$HOME/.syncpilot/update-signing-key.pem}"
KEY_ID="$(sed -n 's/^(define update-key-id "\([^"]*\)".*/\1/p' "$ROOT/racket/syncpilot/version.rkt")"
[[ "$KEY_ID" =~ ^[A-Za-z0-9._-]+$ ]] || {
  echo "error: could not read a valid update-key-id from racket/syncpilot/version.rkt" >&2
  exit 1
}

exec raco rivet update-keys --key "$KEY_PATH" --key-id "$KEY_ID"
