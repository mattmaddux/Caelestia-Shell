# Top menu consolidation

Restructure the shell so most pull-out functionality lives in the top
slide-down menu (currently the "dashboard"). Reduce reliance on the
bottom bar's individual popouts and the right control center.

## Goal

Single primary surface for most shell actions, accessible via swipe-down
or keyboard shortcut. Bottom bar becomes minimal (status display only,
no/few popouts). Right control center either goes away or shrinks
significantly.

## Functionality to move into the top menu

From the **bar bottom-left popouts** (currently shown by tapping bar
icons):
- Wifi popout
- Bluetooth popout
- Power menu (battery, lock status)

From the **bottom-right control center toggles**:
- Wifi on/off
- Bluetooth on/off
- Mic on/off
- Keep awake
- DND
- Game mode

From the **bar itself**:
- Workspace picker
- System tray

From the **bottom**:
- App / utility launcher (becomes the primary tab — see UX split below).

Where it makes sense, combine: e.g., the wifi tab shows both the on/off
toggle *and* the network picker, instead of needing to enter the popout
to pick a network.

## Current state

- Top menu = `modules/dashboard/` (Wrapper, Content, Tabs, Dash,
  WeatherTab, Performance, etc.). Already tabbed.
- Right control center = `modules/controlcenter/` with sub-panes
  (network, bluetooth, audio, dashboard, appearance, taskbar, launcher,
  notifications). Substantial existing UI to repurpose.
- Bar = `modules/bar/` with components (Workspaces, Tray, ActiveWindow,
  Clock, Power) and popouts (Audio, Bluetooth, Network, Battery,
  ActiveWindow, etc.).
- Launcher = `modules/launcher/` with items, services, content list,
  app list, wallpaper list.

Most of the QML for the destination already exists in the control center
panes — they can largely be lifted, restyled to the dashboard's tab
idiom, and dropped in.

## Approach

### Phase 0 — Define the target tab structure

Decide what tabs the new dashboard will have, and what's on each. Strawman:

1. **Launcher** (default, see UX split below) — apps + commands.
2. **Network** — wifi toggle + network list + ethernet + VPN.
3. **Bluetooth** — toggle + device list.
4. **Audio** — output/input pickers + mic toggle.
5. **Workspaces** — workspace overview/picker, system tray.
6. **System** — keep-awake, DND, game mode, brightness, power profile,
   battery, lock/logout/reboot/shutdown.
7. **Existing dashboard tabs** worth keeping (weather, performance,
   media, calendar) — possibly merge or drop.

This needs your input — I shouldn't design the IA without you.

### Phase 1 — Launcher trigger UX split

The launcher needs to appear differently based on how it was opened:
- **Keyboard trigger** (e.g., Super+Space) → search-bar focused at top,
  results list below. Keyboard-driven.
- **Swipe-down trigger** → grid of app icons, no search box (or search
  collapsed behind a button). Touch-driven.

Implementation: thread a `triggerSource` enum through the open call.
Launcher root looks at it and renders one of two layouts.

### Phase 2 — Migrate panels one at a time

For each piece of functionality being moved:
1. Identify the existing implementation (control center pane, popout).
2. Build the dashboard tab equivalent (or adapt existing).
3. Wire the dashboard tab to the same services / state.
4. Remove the old surface (pane / popout) once parity is verified.

Order suggestion: start with the smallest standalone (e.g., bluetooth)
to validate the pattern, then larger (network), then the launcher
(biggest, most behavior).

### Phase 3 — Bar slimming

Once the popouts have moved, remove:
- The corresponding bar popout components.
- Click-to-open behavior on bar icons (or repurpose to "open dashboard
  on this tab").

Keep the bar as a status-display surface.

### Phase 4 — Right control center decision

Either:
- **Remove entirely** if everything moved.
- **Keep slim** as a settings/preferences surface (e.g., appearance pane
  stays, since it doesn't fit the "quick action" model of the top menu).

## Open questions

- **Tab structure:** Need your input on Phase 0. What tabs, what's on
  each?
- **What stays in the control center:** Appearance pane is the obvious
  keeper — anything else?
- **Existing dashboard tabs** (weather, performance, media, calendar):
  keep all? Drop some? Merge into other tabs?
- **Bar popouts on click:** Remove entirely, or repurpose to "jump to
  this tab in the dashboard"?
- **Swipe-down sensitivity:** New triggers needed? Existing swipe
  gesture acceptable?

## Out of scope

- Theme / palette changes to the dashboard itself.
- Reworking Hyprland keybinds globally — only the launcher trigger is
  in scope.
- Touch-first redesign of every individual widget — adopt existing UI
  where it works; only redesign where the existing pane doesn't fit
  the dashboard's tab idiom.
