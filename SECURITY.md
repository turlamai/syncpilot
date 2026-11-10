# Security Policy

SyncPilot wraps the official Resilio Sync (`rslsync`) Web UI in a native
Linux window. Its own surface is loopback-only: the daemon binds
`127.0.0.1` with app-generated credentials, and the embedded web view
loads it through a loopback auth-injecting proxy. Reports are taken
seriously and handled quickly.

## Reporting a vulnerability

Email **security@jrtx.site** (or open a GitHub security advisory on this
repository). Include reproduction steps, affected versions, and your
assessment of impact. You will get an acknowledgment within 72 hours.

Please do not open public issues for security problems.

## Scope

In scope:

- The embedded-Web-UI trust boundary: the generated `rslsync.conf`
  (loopback bind, random credentials, mode 0600
  — `racket/syncpilot/conf.rkt`), the auth-injecting loopback proxy
  (`racket/syncpilot/proxy.rkt`) and everything the app learns from or
  sends to the daemon through the Web UI action API
  (`racket/syncpilot/action-api.rkt`). A request the proxy cannot
  authenticate must never reach the daemon, and daemon credentials must
  never leak into logs or error text.
- Daemon lifecycle and autostart: spawning, adopting an
  already-running daemon, the crash watchdog and the keep-running-on-exit
  path (`racket/syncpilot/manager.rkt`), the XDG autostart integration,
  and first-run install of the pinned official binary from Resilio's CDN
  (`racket/syncpilot/install.rkt`, `scripts/install-rslsync.sh`).
  Adopting a port that answers with different credentials must fail
  closed, not drive a foreign daemon blindly.
- Update trust: verification of the Ed25519-signed `update-stable.json`
  manifest and the downloaded artifact's size and SHA-256
  (`racket/syncpilot/updater.rkt`, `racket/syncpilot/version.rkt`,
  `scripts/make-update-manifest.sh`, `scripts/check-release-signing-key.sh`;
  key id `syncpilot-2026-10`).
- Settings and local data handling: the settings file, the daemon data
  directory and the updates staging area
  (`racket/syncpilot/settings.rkt`; everything lives under
  `~/.local/share/site.jrtx.syncpilot`).
- The host/backend boundary: the GTK4 host renders and interacts; the
  Racket backend (`app/backend.rkt`) decides. Credentials, proxy logic or
  update verification sneaking into the C++ host is a bug.

Out of scope: vulnerabilities in the rslsync binary itself, in the
Resilio Sync protocol, or in Resilio's CDN and licensing infrastructure —
those belong to Resilio, Inc. and should be reported to them. Also out of
scope: social engineering and physical access attacks.

## Design notes reviewers should know

- **Only the official binary ever touches your keys and files.**
  SyncPilot's backend drives `rslsync` through its documented Web UI over
  loopback; all sync traffic (P2P, trackers, relays) is handled by the
  official daemon. SyncPilot holds no share keys, accounts or telemetry.
- **The web view never sees a password.** The proxy injects basic-auth
  credentials into every request it forwards and does not log headers;
  the generated `rslsync.conf` (mode 0600) is the only file holding the
  Web UI credentials. Failure text surfaces ports, paths, HTTP/errno
  strings and remediation — never credentials or sync configuration.
- **Daemon lifecycle fails loudly.** With restart-on-crash the watchdog
  restarts with exponential backoff (2 s doubling to 60 s) while manual
  stops stay honored; with the setting off, a crash surfaces as an
  explicit *crashed* state. A port answering with foreign credentials is
  never adopted — the error names the port and both remedies.
- **Update trust is separate from update installation.** The updater
  verifies the Ed25519 signature, size and SHA-256 against the signed
  manifest before anything is offered or downloaded, but it **never
  installs anything**: it hands you the verified
  `syncpilot-<version>-linux-<arch>.tar.gz` under `<data-dir>/updates`
  and the next step is yours, per install format (extract / package
  install / AppImage swap). Installation staying manual is the declared
  contract of [docs/UPDATE.md](docs/UPDATE.md), not a bug. The signed
  feed does not imply a publisher-signed installer; every release also
  ships `.sha256` sidecars and a combined `SHA256SUMS` for exactly this
  manual verification.
- **First-run rslsync download is pinned.** The CDN download is
  checksum-pinned (rslsync 3.1.2 in `scripts/install-rslsync.sh`), retried
  with backoff, and never fetched from anywhere but Resilio's official
  CDN. Auto-detection prefers binaries already on the machine.
- **Local data is plain files** under
  `~/.local/share/site.jrtx.syncpilot` (settings, `rslsync.conf`,
  `storage/`, `updates/`). Files are not encrypted; protection depends on
  OS user permissions. Nothing here is telemetry — data never leaves the
  machine except through the official daemon's own Resilio Sync traffic.
- **The updater only ever writes under `<data-dir>/updates`.** No update
  path self-replaces the running app or touches the daemon's state, and
  no paid publisher certificate (Apple notarization, Windows
  Authenticode) is claimed for this Linux-only product.

## Supported versions

Security fixes land on `main` first and ship with the next tagged release.
During the 0.x preview there is no LTS branch.
