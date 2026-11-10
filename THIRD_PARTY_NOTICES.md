# Third-party notices

SyncPilot builds on the components below. Each entry names where the
component enters the shipped artifacts and the license it is distributed
under; consult the upstream license files for full terms. The Rivet
toolchain is a first-party TurLamAI project (MIT) consumed as a pinned
package — not third-party code — so it is not listed here.

## Racket CS runtime

Every SyncPilot artifact embeds the statically linked Racket CS runtime
([racket/racket](https://github.com/racket/racket), 9.x). Racket is
distributed under the MIT license and the Apache License 2.0, at your
option; the Racket CS runtime system additionally embeds Chez Scheme,
distributed under the Apache License 2.0 (per Racket's `LICENSE.txt`).

## GTK 4, GLib and the desktop stack

The host is a GTK 4 application (`linux/`). GTK, GLib and GIO are
licensed under the GNU Lesser General Public License, version 2.1 or
later. The host additionally links:

- **WebKitGTK 6.0** (LGPL 2.1 or later) — renders the embedded official
  Resilio Web UI. Optional at build time (`HAVE_WEBKIT`); without it the
  host compiles with the web view replaced by an explanatory boot page.
- **libsecret** (LGPL 2.1 or later) and **JSON-GLib** (LGPL 2.1 or
  later).

Depending on the install shape the libraries come from two places:

- deb / rpm / tar.gz / portable zip: GTK 4, WebKitGTK and the rest of the
  stack are system libraries supplied by the distribution (Ubuntu 24.04+
  ships the required GTK 4 / WebKitGTK 6.0).
- `.AppImage` artifacts: the GTK 4 / WebKitGTK dependency closure is
  bundled into the image so it also runs on distributions older than the
  build image.

## curses, LZ4, zlib

The host links the system curses, LZ4 and zlib libraries (build
requirements in `linux/CMakeLists.txt`), which the embedded Racket CS
runtime uses. curses (ncurses) is distributed under an MIT-style
X-consortium license; LZ4's library code is BSD 2-Clause; zlib carries
the zlib license. On deb / rpm / tar.gz installs they are supplied by the
distribution; AppImage artifacts include them in the dependency closure.

## AppImageKit runtime (`.AppImage` artifacts)

`.AppImage` release artifacts contain the type-2 AppImage runtime from
[AppImage/AppImageKit](https://github.com/AppImage/AppImageKit), licensed
MIT. The build tool is the official `appimagetool` release fetched and
checksum-pinned by Rivet. AppImageKit's license does not apply to the
contents of the AppImage: those are SyncPilot's AGPL-3.0 payload plus the
entries above.

## Resilio Sync (`rslsync`) — not open source, not bundled

SyncPilot drives the **official Resilio Sync binary**. That binary is
proprietary software of [Resilio, Inc.](https://www.resilio.com) and is
**not** distributed under AGPL-3.0 or included in SyncPilot's release
artifacts: it is downloaded at first run directly from Resilio's official
CDN (version-pinned and SHA-256-checked in `scripts/install-rslsync.sh`)
or installed by the user and located via auto-detection/Settings. Its
use is governed by Resilio's own license and service terms, which apply
to the binary and to any syncing you do with it. SyncPilot (AGPL-3.0) is
a separate work that starts, supervises and renders the Web UI of that
binary over loopback; SyncPilot is not affiliated with Resilio, Inc., and
"Resilio Sync" is a trademark of its respective owner.
