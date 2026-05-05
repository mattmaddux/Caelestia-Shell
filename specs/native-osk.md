# Native on-screen keyboard

A shell-native virtual keyboard for the touchscreen, replacing the
externally-launched OSK currently triggered by text-input focus.

## Goal

Build the OSK as a Quickshell module so it lives in the same QML/styling
ecosystem as the rest of the shell. Full control over layout, theming,
and behavior. Triggered automatically on text-input focus (when no
hardware keyboard is attached) or manually via gesture/keybind.

## Current state

- An external OSK is launched via existing detection infrastructure when
  a text field is selected and no hardware keyboard is present. Need to
  identify which trigger (likely a process spawn keyed off the
  `text-input-v3` Wayland protocol or input-method state).
- Wayland protocols relevant:
  - `text-input-v3` — clients announce text-input focus; OSK reads.
  - `virtual-keyboard-v1` — OSK injects keystrokes back to the focused
    client.
  - `input-method-v2` — full input-method client (more complex; allows
    composition, candidate windows, etc.).
- Quickshell exposes Wayland integration but support for these specific
  protocols needs to be verified.

## Approach

### Phase 0 — Spike (validate before committing)

Before designing UI, confirm we can actually inject keystrokes from
QML/Quickshell:

1. Identify which Wayland protocol Quickshell exposes for virtual
   keyboards. Check `Quickshell.Wayland` types.
2. If none: fall back to shelling out to `wtype` (a CLI virtual-keyboard
   tool that uses `virtual-keyboard-v1` directly).
3. Test injection works while a text field is focused on a real client
   (e.g., a terminal).

If neither Quickshell-native nor `wtype` works, this project blocks until
that's resolved.

### Phase 1 — Find existing trigger

Locate where the current OSK launch happens:
- Probably a Process or QML component listening for text-input focus.
- Likely in a service or a top-level shell module.
- Goal: replace the "spawn external" with "show our QML overlay."

### Phase 2 — Layout

Standard QWERTY US layout to start. Layers:
- Letters (default).
- Numbers + symbols.
- Modifier shift (capitals, alt symbols).

Layout structure as a QML data model (rows of key descriptors with
label, output, width-multiplier). Renders via Repeater inside a Column
of Rows. Easy to swap layouts by changing the model.

Key types:
- Character keys (output a single char).
- Modifier keys (Shift, Ctrl, Alt — sticky-on-tap, latched-on-double-tap).
- Layer keys (switch to numeric/symbols layer).
- Special keys (Backspace, Enter, Space, Tab).

### Phase 3 — Surface

Anchor at the bottom of the screen via `WlrLayerShell` (exclusive zone
optional — probably *not* exclusive so windows aren't resized; rely on
overlay).

Auto-show when text-input focus is active and no HW keyboard. Auto-hide
on focus loss.

### Phase 4 — Theming + polish

- Match shell tokens (`Tokens.rounding`, palette colors).
- Per-key haptic-style state layers (matches existing `StateLayer`
  component pattern).
- Smooth slide-up/slide-down animation on show/hide.

## Open questions

- **Injection mechanism:** Quickshell-native vs `wtype`? (Phase 0 spike.)
- **Layout customization:** Is per-language layout switching needed?
  Defer to v2 unless explicitly wanted.
- **Sizing:** Fixed % of screen height, or content-driven? On the Z13's
  small screen, real estate is tight in landscape vs portrait.
- **HW keyboard detection:** How is "no HW keyboard" currently detected?
  Match that signal so the new OSK shows in the same conditions.
- **Number-row vs separate layer:** First row of numbers always visible,
  or hidden behind a layer toggle? Phone-style hides; tablet-style shows.

## Out of scope (v1)

- Composition / IME / candidate windows (that's `input-method-v2`
  territory; full IME support is a separate project).
- Word prediction / autocomplete.
- Swipe typing.
- Multiple language layouts.
- Floating / resizable window mode (always docked at bottom).
