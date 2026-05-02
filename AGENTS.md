# Caelestia-Shell (Matt's fork)

## MANDATORY: Use td for Task Management

Run td usage --new-session at conversation start (or after /clear). This tells you what to work on next.

Sessions are automatic (based on terminal/agent context). Optional:
- td session "name" to label the current session
- td session --new to force a new session in the same context

Use td usage -q after first read.

Personal fork of [`caelestia-dots/shell`](https://github.com/caelestia-dots/shell).
Origin: `git@github.com:mattmaddux/Caelestia-Shell.git`. Upstream remote is
kept but full divergence is expected — do not assume PR-back.

Companion CLI fork at `~/Dev/Caelestia-CLI/`. Dotfiles at `~/.dotfiles/`
(Caelestia dots have been merged in; that fork is gone).

## What this is

Quickshell-based desktop shell. Two layers:

- **QML layer** (`shell.qml`, `modules/`, `components/`, `services/`,
  `utils/`, `assets/`) — UI, hot-reloads from disk via Quickshell's file
  watcher. No rebuild needed for QML edits.
- **C++ plugin** (`plugin/src/Caelestia/`) — compiled `.so` loaded by `qs`
  at runtime. Provides QML types backed by native code:
  - `appdb`, `cutils`, `imageanalyser`, `qalculator`, `requests`, `toaster`
  - `Blobs/` — custom QML scene-graph items + GLSL shaders
  - `Components/lazylistview`
  - `Models/filesystemmodel`
  - `Services/` — `audiocollector`, `audioprovider`, `beattracker`,
    `cavaprovider`
  - Plus `extras/` (small `version.cpp`)

  Editing C++ requires a rebuild (`cmake --build`). Editing QML does not.

Top-level `CMakeLists.txt` builds three modules: `extras`, `plugin`, `shell`.
The `shell` module just installs QML files into
`/etc/xdg/quickshell/caelestia` (or a chosen prefix). `plugin` produces a
`.so` that lands in `/usr/lib/qt6/qml/...`. `extras` is small native
helpers.

## Current state

- Dockerized build is in place. `Dockerfile` (Arch base, builds `libcava`
  from AUR via `makepkg` since it's not in the official repos) +
  `Taskfile.yml` (`go-task`) drive everything. `task build` compiles in
  the container and stages a deployable tree at `build/staging/`.
  `task install` moves staging into user-local dirs (host-only, no
  container). `task run` / `task prod` launch the fork. `task clean` /
  `task uninstall` / `task shell` are also there.
- User-local install layout:
  - QML → `~/.config/quickshell/caelestia/`
  - QML plugin `.so` → `~/.local/lib/qt6/qml/Caelestia/`
  - Native helpers → `~/.local/lib/caelestia/`
- AUR `caelestia-meta` / `caelestia-shell` / `caelestia-cli` have been
  removed; the fork (shell here, CLI from `~/Dev/Caelestia-CLI/`) is the
  only install. Hyprland's `env.conf` sets `PATH` (with `~/.local/bin`
  prepended), `CAELESTIA_LIB_DIR`, and `QML2_IMPORT_PATH` so exec-once
  and keybinds resolve the fork CLI and qs finds the user-local plugin
  + helpers.
- The Hyprland `exec-once` line `caelestia shell -d` autostarts the fork
  at login. To swap from `task dev` back to the deployed install:
  `task prod`.
- During dotfile consolidation, Caelestia's `~/.local/share/caelestia/`
  staging dir was emptied — runtime files have all been moved into
  `~/.dotfiles/.config/`.

## Build/install gotchas

- **ABI matters.** Plugin links against system Qt6 and is `dlopen`'d by
  host `qs`. The Dockerfile uses `archlinux:latest` and rolls forward;
  if a host upgrade changes Qt6/glibc ABI, rebuild the image
  (`task image` after `docker rmi caelestia-shell-build` to force).
- **Build deps in `Dockerfile`**: `base-devel git cmake ninja pkgconf
  qt6-base qt6-declarative qt6-shadertools aubio pipewire libqalculate`,
  plus `libcava` built via `makepkg` from AUR by a non-root `builder`
  user. Don't drop `qt6-shadertools` — the `Blobs/` subdir compiles
  GLSL shaders.
- **Bind-mount, not copy.** The container sees the repo at `/workspace`;
  everything in `build/` (including `staging/`) lives on the host. Pass
  container paths (`/workspace/...`) to processes inside the container,
  host paths to host-side `mv`/`rm`.
- **Git history must be present.** `CMakeLists.txt` shells out to
  `git describe` and `git rev-parse HEAD` — don't shallow-clone or pass
  `-DVERSION=... -DGIT_REVISION=...` explicitly.

## Immediate goals

No specific changes queued — customization is open-ended from here. Check
`td list` or `td next` for what's currently in flight.

## Conventions / things to know

- **QML hot-reloads. C++ does not.** Iterate on UI without rebuilding.
  Only rebuild for plugin changes.
- **Fish-first.** Helper scripts should be fish unless there's a reason
  not to.
- **Don't chain Bash commands with `&&` in tool calls** — issue separate
  Bash calls (each auto-approves under Matt's permission settings). This
  applies to agent tool use, not to scripts on disk.
- **Confirm before installing system packages or running `pacman -R`.**
- **Matt commits and pushes himself.** Stage and write messages, don't
  commit/push without an explicit ask.
- **The compiler flags in `CMakeLists.txt` are strict** (`-Wall -Wextra
  -Wpedantic -Wshadow -Wconversion -Wold-style-cast` etc.). Any C++ change
  needs to compile clean under those.
- Hardware: ROG Flow Z13 (CachyOS / Hyprland / Caelestia). External
  monitor enumerates as DP-1, DP-2, or HDMI-A-1 depending on USB-C port —
  monitor-related shell logic should handle all three.

## Pointers

- CLI fork: `~/Dev/Caelestia-CLI/` (has its own AGENTS.md). The shell
  reaches the CLI via `caelestia shell ...`.
- Dotfiles: `~/.dotfiles/` (Hyprland keybinds in
  `.config/hypr/hyprland/keybinds.conf`, shell config goes in
  `~/.config/caelestia/shell.json` — not currently tracked, create as
  needed).
- Quickshell docs: https://quickshell.outfoxxed.me
- Upstream issues/PRs: https://github.com/caelestia-dots/shell
