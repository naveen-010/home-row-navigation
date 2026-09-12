# Home Row Navigation

System-wide Vim-style navigation, a smarter Caps key, and optional mouse control
from the home row. Works on Linux with ordinary application shortcuts—no editor
plugin or modal typing required.

Hold **Tab** and use **H J K L** for **← ↓ ↑ →**. Tap Tab by itself for a normal Tab.

## Features

- Home-row arrows, Home/End, Page Up/Down, F1–F12, and programming symbols.
- Caps tapped in under **200 ms** sends Escape.
- Caps used with another key acts as Control; holding it alone and releasing
  it sends no Escape.
- **Tab + Caps** toggles actual Caps Lock.
- Normal **Ctrl + Tab** and **Alt + Tab**.
- Optional mouse movement, clicks, dragging, and scrolling, toggled with Right Shift.
- Optional Lenovo IdeaPad Fn-lock light indicating mouse mode.

The motivation is simple: choosing a browser autocomplete suggestion, recalling a
terminal command, or moving through a form should not require reaching for the
arrow keys. This setup sends the same ordinary keys those applications already use.

## Two tools, separate responsibilities

```text
Physical keyboard → keyd → keyd virtual keyboard → Kanata → desktop
                     │                             │
             Keyboard mappings                Mouse mode
```

**keyd owns all keyboard mappings.** Use it alone for navigation and Caps behavior.
**Kanata adds mouse mode.** Its normal layer passes keyd's output through, except
for Right Shift's mouse toggle. Kanata is optional, but this Kanata config needs keyd.

The two remappers can run together because their inputs are explicitly separated:

- Kanata reads only `keyd virtual keyboard`.
- keyd excludes Kanata's output by its **full device ID**.
- Each daemon runs once. Do not combine the old all-in-one Kanata config with keyd.

The supplied exclusion, `0001:0001:0e03123f`, was verified with Kanata 1.11.0.
Verify it on your machine before enabling both daemons; the installation guide
includes a check. Never exclude only `0001:0001`: physical laptop keyboards can
share that vendor/product pair.

## Shortcuts

### Keyboard

Hold Tab while pressing a key below:

| Keys | Output |
| --- | --- |
| H / J / K / L | Left / Down / Up / Right |
| Y / O | Home / End |
| U / M | Page Up / Page Down |
| 1 … 0 | F1 … F10 |
| - / = | F11 / F12 |
| W / E | `(` / `)` |
| S / D | `{` / `}` |
| X / C | `[` / `]` |
| R / F | `<` / `>` |
| G / V | `;` / `=` |
| Caps | Toggle Caps Lock |

Symbols assume US QWERTY. Navigation emits ordinary keycodes and works in browser
URL bars, terminals, menus, dialogs, and other applications that accept those keys.

| Action | Result |
| --- | --- |
| Tap Caps, release before 200 ms | Escape |
| Hold Caps for 200 ms or longer, release alone | No Escape or typed character |
| Press another key while Caps is down | Control chord |
| Press/release Tab alone, even after a long hold | Tab |
| Hold Tab and press another mapped key | Navigation/symbol layer |
| Ctrl + Tab / Alt + Tab | Normal application/window switching |

Control modifier events may occur while Caps is held; “release alone” means no
Escape or character is sent, not that the input stream contains zero events.
The 200 ms threshold is local to the Caps binding; Tab has no tap timeout.

### Mouse (optional Kanata layer)

Tap **Right Shift** to enter mouse mode. Tap it again, press **Escape**, or tap
**Caps** to leave. Right Shift has a 200 ms tap/hold threshold.

| Key | Mouse action |
| --- | --- |
| H / J / K / L | Move left / down / up / right |
| A | Left button (hold for dragging) |
| G | Middle button |
| ; | Right button |
| U / E | Scroll up / down |
| Hold Right Shift | Temporarily restore normal typing with Shift held |

Other input is suppressed in mouse mode, including navigation/F-key output from
keyd. Release Right Shift after temporary typing to return to mouse mode.
Tab + Caps toggles Caps Lock in normal keyboard mode, not in mouse mode.

## Installation

Tested on Linux with **keyd 2.6.0**, **Kanata 1.11.0**, and KDE Plasma Wayland.
X11 is also supported by the remappers. Linux with systemd and administrator
access is required for the main installation path.

1. Install keyd; install Kanata too if you want mouse mode.
2. Clone the repo and validate the configs.
3. Use the installer to back up and stage files.
4. Verify the device exclusion and activate the services.

**[Full installation, migration, updates, and rollback guide →](docs/install.md)**

```bash
git clone https://github.com/naveen-010/home-row-navigation.git
cd home-row-navigation

# Preview only; no files or services change.
bash scripts/install.sh --dry-run

# Stage keyboard + mouse configs and the system service.
sudo bash scripts/install.sh

# Or stage just the keyboard config:
sudo bash scripts/install.sh --keyboard-only
```

The installer does **not** install packages, start/restart remappers, change
desktop keyboard settings, or install the optional LED helper. Follow the guide
before activation. Existing destination files are saved under a unique
`/var/backups/home-row-navigation.*` directory.

Upgrading from the old repository? The guide covers stopping the old user/system
Kanata instance before using the new `home-row-navigation-mouse.service`.

## Customization and checks

- Edit keyboard mappings and the Caps threshold in [keyd/default.conf](keyd/default.conf).
- Edit mouse bindings, acceleration, scrolling, and Right Shift timing in
  [kanata/kanata.kbd](kanata/kanata.kbd).
- Keep Kanata's output name and keyd's exclusion in sync.
- Disable desktop Caps remapping options so Tab + Caps reaches actual Caps Lock.
  KDE's loaded keymap may need a configuration notification; see the guide.

```bash
bash scripts/check.sh
bash scripts/check.sh --keyboard-only
sudo bash scripts/check-device-id.sh /etc/keyd/default.conf
```

The device check needs a running Kanata output device. It reports device
announcements only, not typed keys. It checks the exclusion, not every possible
setting in unrelated remapper configs.

## Optional Fn-lock indicator

[Setup instructions →](docs/install.md#optional-lenovo-fn-lock-indicator)

The included Python helper observes Kanata's localhost control server and sets
the Lenovo IdeaPad Fn-lock state while mouse mode is active. This affects the
**real Fn-lock state and function-key behavior**, not just a cosmetic LED.
It is specific to `/sys/bus/platform/devices/VPC2004:00/fn_lock`; mouse mode
works without it.

## Repository layout

| Path | Purpose |
| --- | --- |
| `keyd/default.conf` | All keyboard mappings and Kanata output exclusion |
| `kanata/kanata.kbd` | Mouse layer and keyd input filter |
| `kanata/home-row-navigation-mouse.service` | Main system service, ordered after keyd |
| `scripts/install.sh` | Validate, back up, and stage files; supports dry run |
| `scripts/check.sh` | Config validators and shell syntax checks |
| `scripts/check-device-id.sh` | Verify the Kanata output exclusion |
| `docs/install.md` | Installation, migration, KDE fix, troubleshooting, rollback |
| `kanata/fn-lock-indicator.*` | Optional Lenovo helper and user service |
| `kanata/99-kanata-fnlock.rules` | Optional Fn-lock write permission |
| `kanata/kanata.service`, `kanata/99-input.rules` | Alternative user-service setup |
| `kanata/keyd-ordering.conf` | Drop-in for an existing system Kanata service |
