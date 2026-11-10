# Contributing to SyncPilot

Thank you for looking under the hood. SyncPilot is free software
(AGPL-3.0, see [LICENSE](LICENSE)): by submitting a pull request you
agree your contribution is licensed under AGPL-3.0.

## Ground rules

1. **SyncPilot is Linux-only by decision.** The GTK4 host under `linux/`
   is the only first-party host. Do not add empty Windows/macOS hosts and
   do not file the absence of other platforms as a product defect
   ([AGENTS.md](AGENTS.md)).
2. **The RPC surface is the contract.** `app/backend.rkt`'s
   `define-rpc` declarations are the host's only data channel; the
   domain core lives in `racket/syncpilot/`. Changing any signature is a
   host + backend change in the same commit — regenerate with
   `raco rivet build` (`linux/GeneratedBackend.hpp` is a build input,
   never hand-edit it). The host renders and interacts; timers,
   scheduling, HTTP and storage all stay in the Racket backend.
3. **i18n is single-source.** All user-visible strings live in
   `shared/i18n/{zh,en}.json` (zh is the default); keep both languages in
   exact key parity and regenerate `linux/GeneratedStrings.h` with
   `node scripts/gen-c-strings.mjs`. Public docs are English with a
   complete Chinese path (`*.zh-CN.md`) — update both when installation,
   recovery, privacy or platform facts change.
4. **The update contract is written down — keep it true.**
   [docs/UPDATE.md](docs/UPDATE.md) is the single source of truth for the
   updater: Ed25519-signed feed (key id `syncpilot-2026-10`), size +
   SHA-256 verification before download trust, and **installation stays a
   manual step per install format**. The 24 h throttle and the manual
   handoff are declared behavior, not bugs to fix silently.
5. **The daemon contract is drop-in.** Data paths and formats are
   byte-identical with 0.4.x (`~/.local/share/site.jrtx.syncpilot`):
   `syncpilot-settings.json`, `rslsync.conf` (mode 0600), `storage/`.
   Breaking migration is a contract break. Protocol facts proven live
   against rslsync 3.1.2 live in [docs/api-verified.md](docs/api-verified.md)
   (required reading before touching the daemon client); a foreign daemon
   on the configured port must keep failing closed.
6. **`rivet-acceptance.rktd` is the executable definition of done.** Do
   not delete requirements, weaken assertions, substitute CLI checks for
   GUI behavior, or reuse old evidence to turn a result green.
7. **Fail honestly.** A crash surfaces as an explicit *crashed* state or
   a watchdog restart — never a silent fallback; error text names the
   failure and the remedy, and never contains credentials.
8. **Tests pin contracts.** If you change behavior a test covers, change
   the test in the same commit and say why.

## Before you push

```bash
raco test racket/                        # domain-core contract tests
bash scripts/check-release-version.sh    # VERSION == rivet.rktd == updater == generated client
bash scripts/test-release-signing.sh     # offline release-signing negative tests
```

These mirror the CI `release-metadata` and `racket-tests` jobs. The
`linux-host` job additionally compiles the GTK4 + WebKitGTK host, runs
the real-daemon integration smoke (rslsync spawned, Web UI on
`127.0.0.1:38889`, proxy answers `/gui/`) and packages with a launch
smoke — Linux developers should run `raco rivet build` before pushing
host changes and say whether the build was verified locally. For the
full Linux product acceptance run `raco rivet acceptance --json`.

## Reporting issues

Include: distribution + version, SyncPilot version (release or build),
install shape (deb / rpm / AppImage / tar.gz / portable zip), rslsync
source (first-run CDN install, auto-detected path or Settings), steps to
reproduce, and for daemon/proxy issues the exact error text from the UI.
Security issues go through [SECURITY.md](SECURITY.md), not public issues.
