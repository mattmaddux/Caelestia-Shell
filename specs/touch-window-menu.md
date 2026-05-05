# Touch window menu

A small touch-triggered popup, anchored to the window the user touched, with
three actions for fast one-handed window management on the touchscreen.

## Goal

Provide a touch-friendly alternative to keyboard window-management shortcuts.
Triggered by a multi-finger gesture on the target window, the popup offers
four actions in a 2×2 grid styled like the session menu buttons (large
rounded squares, easy tap targets):

1. **Close window** — graceful close (not force-kill).
2. **Move to workspace** — replaces the 2×2 grid with a workspace picker
   (3×3 grid for workspaces 1-9, with `0` centered below for workspace 10),
   styled like the session buttons.
3. **Swap with window** — enter a "tap target" mode; next tap on a
   window swaps the two on the current workspace.
4. **Info** — opens the existing `modules/windowinfo/` popup, which already
   surfaces window metadata and a kill button.

## Current state

- Hyprland gesture infrastructure already in use:
  `~/.dotfiles/.config/hypr/hyprland/gestures.conf` defines existing gestures
  (e.g. 3-finger swipe down → toggle special workspace).
- Dispatch syntax for window operations:
  - `hyprctl dispatch closewindow address:0x<addr>` — graceful close.
  - `hyprctl dispatch movetoworkspace <id>,address:0x<addr>` — move to ws.
  - `hyprctl dispatch swapwindow <direction>` — swaps with neighbor (not
    arbitrary window). For arbitrary swap, no direct dispatch — likely need
    move-to-special, focus other, move-back pattern, or use plugin.
- Window enumeration via `hyprctl clients -j` (JSON).
- Existing `WindowInfo` module (`modules/windowinfo/`) shows on-hover popup
  with similar buttons (move-to-workspace, float, pin, kill) — useful
  reference for layout and dispatch patterns.

## Approach

### Trigger

Use Hyprland's gesture system. Candidate: 3-finger tap (no swipe). If
Hyprland gestures don't support pure tap (only swipe), fall back to a
short 3-finger swipe with very small threshold, or use a longpress.

Configure in `gestures.conf` to dispatch a custom IPC call to the shell:
```
gesture = 3, tap, exec, caelestia shell touchMenu open
```
(or `qs -c caelestia ipc call touchMenu open`).

The shell receives the IPC call, queries `hyprctl cursorpos` and
`hyprctl clients -j` to find which window is under the cursor, and shows
the popup centered on that window.

### Popup UI

- New module: `modules/touchmenu/` with `Wrapper.qml`, `Content.qml`.
- 2×2 grid of large icon-only buttons styled like `modules/session/`
  SessionButton (square rounded, MaterialIcon centered).
- Anchored to the target window's position (Hyprland gives at/size).
- Auto-dismiss on:
  - Outside tap.
  - Action selection (except "Move to workspace", which transitions the
    grid in-place).
  - 5s timeout (configurable).

### Move-to-workspace transition

Tapping the move-to-workspace button replaces the 2×2 grid in-place with
a 3×3 grid of workspace buttons (1-9) plus a `0` button centered beneath
(workspace 10). Same button style. Tapping a workspace number issues
`movetoworkspace <n>,address:0x<addr>` and dismisses the popup. Tapping
outside or back-button returns to the 2×2 root grid.

### Swap-with-another flow

This is the trickiest interaction.

**Option A — Transparent fullscreen overlay:**
After tapping "swap", the popup closes and a transparent fullscreen layer
(`WlrLayerShell` with `KeyboardInteractivity.OnDemand`) opens. On next
click/tap, read cursor pos, find target window via `hyprctl clients`, then
issue swap dispatches.

**Option B — Hyprland focus polling:**
After tapping "swap", show a small overlay banner ("Tap a window to swap").
Listen for next focus change via Hypr.activeClientChanged, then swap.

Option A gives more control (we get the exact tap event) but adds a
fullscreen layer; Option B is lighter but relies on focus-change-on-click
behavior. Probably A.

### Window swap dispatch

Hyprland has no "swap two arbitrary windows by address" dispatcher.
v1 implementation: direction-based `swapwindow` with focus juggling.

Algorithm:
1. Compute direction from source A → target B (based on center coords;
   pick horizontal vs vertical by larger delta).
2. `focuswindow address:0xA`, then `swapwindow <direction>`.

**Known limitation:** `swapwindow` swaps with the *adjacent* window in
the chosen direction. If A and B aren't adjacent in that direction, A
swaps with the wrong window. For typical touch use (2-3 visible windows
in a layout), this is reliable; for 4+ windows or non-axis-aligned
layouts, the behavior may surprise. Document this; revisit if it
becomes a real problem.

## Open questions

- **Gesture choice:** Does Hyprland support a true tap (no movement)?
  Verify in Hyprland docs / config. If not, what's the alternative
  (longpress? 3-finger short swipe?). Worth checking what gesture plugin
  is in use (libinput? touchgestures?).
- **Address of cursor-target window:** Confirm `hyprctl clients -j` +
  `hyprctl cursorpos` gives reliable hit-test, or whether to use
  `hyprctl activeworkspace` and iterate clients with at/size bounds.
- **Swap dispatch UX:** Acceptable to have a brief visual flicker during
  swap, or does it need to look instant?

## Out of scope

- Customization of the three actions (could come later as config).
- Gestures other than the trigger (e.g., 2-finger tap for something else).
- Touch interactions in the popup itself beyond tap (no swipe-to-dismiss
  for v1 — outside tap is enough).
