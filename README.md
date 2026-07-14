# Home Row Navigation

System-wide Vim-style arrow keys on Linux—without turning every application into
Vim.

Hold <kbd>Tab</kbd>, then use <kbd>H</kbd><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd>:

```text
H  J  K  L
←  ↓  ↑  →
```

Your hands stay on the home row in browser address bars, terminals, search
boxes, autocomplete menus, file pickers, forms, and almost anywhere else that
already understands arrow keys.

This repository contains two versions of the setup:

- **keyd** for the small, readable, navigation-only version.
- **Kanata** for the same navigation layer plus a toggleable keyboard-controlled
  mouse mode.

> [!IMPORTANT]
> Use **one remapper at a time**. Running keyd and Kanata together can cause
> duplicated or confusing remaps.

## The idea

The original problem was painfully ordinary: type `goo` into a browser address
bar and the suggestions appear below—Google, google.com, Gmail, and so on. To
choose one, the right hand has to leave the home row and reach for arrow keys
that are awkwardly placed on many keyboards.

My first thought was: **I need system-wide Vim.** Press <kbd>Esc</kbd>, use
<kbd>J</kbd> and <kbd>K</kbd>, then return to insert mode.

But navigation was the real need, not a full modal editor. Applications already
know what arrow keys mean. The simpler answer was to put those arrow keys under
the home row:

- Browser suggestions: hold <kbd>Tab</kbd> and tap <kbd>J</kbd> or <kbd>K</kbd>.
- Previous terminal command: <kbd>Tab</kbd> + <kbd>K</kbd>.
- Accept a right-arrow autocomplete suggestion: <kbd>Tab</kbd> + <kbd>L</kbd>.
- Move through text, menus, dialogs, and history without leaving the home row.

There is no mode to enter, no mode to leave, and no application-specific plugin.
It is just a temporary keyboard layer that emits ordinary arrow keys system-wide.

## Shortcut reference

### Navigation layer

Hold <kbd>Tab</kbd> while pressing any of these keys:

| Shortcut | Output | Shortcut | Output |
| --- | --- | --- | --- |
| <kbd>Tab</kbd> + <kbd>H</kbd> | Left arrow | <kbd>Tab</kbd> + <kbd>Y</kbd> | Home |
| <kbd>Tab</kbd> + <kbd>J</kbd> | Down arrow | <kbd>Tab</kbd> + <kbd>U</kbd> | Page Up |
| <kbd>Tab</kbd> + <kbd>K</kbd> | Up arrow | <kbd>Tab</kbd> + <kbd>O</kbd> | End |
| <kbd>Tab</kbd> + <kbd>L</kbd> | Right arrow | <kbd>Tab</kbd> + <kbd>M</kbd> | Page Down |
| <kbd>Tab</kbd> + <kbd>1</kbd>…<kbd>0</kbd> | F1…F10 | <kbd>Tab</kbd> + <kbd>-</kbd>/<kbd>=</kbd> | F11/F12 |

The layer also keeps common programming symbols nearby:

| Shortcut | Output | Shortcut | Output |
| --- | --- | --- | --- |
| <kbd>Tab</kbd> + <kbd>W</kbd>/<kbd>E</kbd> | `(` / `)` | <kbd>Tab</kbd> + <kbd>S</kbd>/<kbd>D</kbd> | `{` / `}` |
| <kbd>Tab</kbd> + <kbd>X</kbd>/<kbd>C</kbd> | `[` / `]` | <kbd>Tab</kbd> + <kbd>F</kbd> | `>` |
| <kbd>Tab</kbd> + <kbd>G</kbd> | `;` | <kbd>Tab</kbd> + <kbd>V</kbd> | `=` |
| <kbd>Tab</kbd> + <kbd>R</kbd> | `<` in Kanata | | |

The symbol mappings assume a US QWERTY layout. The navigation mappings do not
depend on the characters produced by those symbols.

### Tap/hold keys

| Key | Tap | Hold |
| --- | --- | --- |
| <kbd>Tab</kbd> | Tab | Navigation layer |
| <kbd>Caps Lock</kbd> | Escape | Left Control |
| <kbd>Right Shift</kbd> (Kanata only) | Toggle mouse mode | Right Shift |

The keyd config explicitly preserves both <kbd>Ctrl</kbd> + <kbd>Tab</kbd> and
<kbd>Alt</kbd> + <kbd>Tab</kbd>. The Kanata config explicitly preserves
<kbd>Ctrl</kbd> + <kbd>Tab</kbd>.

### Kanata mouse mode

Tap <kbd>Right Shift</kbd> once to enter mouse mode. Tap it again—or press
<kbd>Esc</kbd>—to return to the normal keyboard.

| Key | Mouse action |
| --- | --- |
| <kbd>H</kbd><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd> | Move left/down/up/right |
| <kbd>A</kbd> | Left click |
| <kbd>G</kbd> | Middle click |
| <kbd>;</kbd> | Right click |
| <kbd>U</kbd> | Scroll up |
| <kbd>E</kbd> | Scroll down |

Most other keys are disabled while mouse mode is active, which helps prevent
accidental typing. Holding <kbd>Right Shift</kbd> temporarily restores the normal
keyboard with Shift held.

## Which config should I use?

- **Only want the keyboard shortcuts? Use keyd.** It provides the home-row
  arrows, navigation keys, F1–F12 layer, and Caps Lock tap/hold behavior. Its
  config is dead simple to read, understand, and edit—even if you have never
  used a keyboard remapper before.
- **Want the keyboard shortcuts plus mouse control from the keyboard? Use
  Kanata.** It adds the toggleable Right Shift mouse mode, including movement,
  clicking, and scrolling. The tradeoff is that Kanata's Lisp-like config is
  unusual, much less friendly, and considerably harder to understand or modify.

In short: choose **keyd** unless you specifically want mouse mode. Kanata is the
more capable option here, but keyd is by far the easier one to maintain.

## Requirements

- Linux. This repository's configs and services are Linux-specific.
- A US ANSI/QWERTY keyboard for the symbol layer exactly as written.
- Root access for installing the remapper and input permissions.
- Python 3 only if you use the optional Fn-lock indicator.

Clone the repository, then choose one setup below:

```bash
git clone https://github.com/YOUR-USERNAME/home-row-navigation.git
cd home-row-navigation
```

> [!CAUTION]
> The install commands below replace configs at their destination paths. Back up
> an existing keyd or Kanata config first if it contains mappings you need.

## Setup A: keyd (recommended for navigation only)

Install keyd using your distribution package or the
[official keyd installation instructions](https://github.com/rvaiya/keyd#installation).
Then install and validate the config:

```bash
sudo install -Dm644 keyd/default.conf /etc/keyd/default.conf
sudo keyd check /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload
```

Check its status and logs:

```bash
systemctl status keyd
sudo journalctl -eu keyd
```

Changes to the config can be applied with `sudo keyd reload`.

## Setup B: Kanata (navigation + mouse mode)

### 1. Install Kanata

Use a binary from the
[official Kanata releases](https://github.com/jtroo/kanata/releases), your
distribution package, or Cargo:

```bash
cargo install kanata
kanata --version
```

### 2. Grant Linux input access

Kanata needs access to the `input` and `uinput` subsystems. These commands follow
the [official Kanata Linux setup](https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md):

```bash
getent group uinput >/dev/null || sudo groupadd --system uinput
sudo usermod -aG input,uinput "$USER"
sudo modprobe uinput
printf 'uinput\n' | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
sudo install -Dm644 kanata/99-input.rules /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Log out and back in so the new groups take effect. Verify that `groups` includes
both `input` and `uinput`, and that `/dev/uinput` is group-writable:

```bash
groups
ls -l /dev/uinput
```

Giving a login user input-device access has security implications: software
running as that user can potentially observe or inject input. See the official
Kanata setup guide above before using this on a shared or high-security machine.

### 3. Install the config and user service

```bash
install -Dm644 kanata/kanata.kbd ~/.config/kanata/kanata.kbd
install -Dm644 kanata/kanata.service ~/.config/systemd/user/kanata.service
kanata --check --cfg ~/.config/kanata/kanata.kbd
systemctl --user daemon-reload
systemctl --user enable --now kanata.service
```

Check its status and logs:

```bash
systemctl --user status kanata.service
journalctl --user -eu kanata.service
```

The service binds Kanata's optional control server only to
`127.0.0.1:5829`. The local Fn-lock indicator below uses it to observe layer
changes.

## Optional: Fn-lock light as the mouse-mode indicator

The included helper turns the Fn-lock light on while Kanata is in mouse mode and
off when mouse mode ends. It reproduces the original **Lenovo IdeaPad-specific**
setup; it is not portable to every keyboard or laptop.

First check whether the expected interface exists:

```bash
test -e /sys/bus/platform/devices/VPC2004:00/fn_lock \
  && echo 'Supported Lenovo fn_lock path found' \
  || echo 'This indicator will not work on this hardware'
```

If it exists, install the permission rule, helper, and service:

```bash
sudo install -Dm644 kanata/99-kanata-fnlock.rules \
  /etc/udev/rules.d/99-kanata-fnlock.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=platform

install -Dm755 kanata/fn-lock-indicator.py \
  ~/.config/kanata/fn-lock-indicator.py
install -Dm644 kanata/fn-lock-indicator.service \
  ~/.config/systemd/user/fn-lock-indicator.service
systemctl --user daemon-reload
systemctl --user enable --now fn-lock-indicator.service
```

This controls the laptop's real Fn-lock state, not just the light. Function-key
behavior is therefore locked while mouse mode is active. Mouse mode itself works
without this optional helper.

## Switching between keyd and Kanata

From Kanata to keyd:

```bash
systemctl --user disable --now kanata.service
sudo systemctl enable --now keyd
```

From keyd to Kanata:

```bash
sudo systemctl disable --now keyd
systemctl --user enable --now kanata.service
```

## Frequently asked questions

### How do I use arrow keys without leaving the home row?

Hold <kbd>Tab</kbd> and press <kbd>H</kbd>, <kbd>J</kbd>, <kbd>K</kbd>, or
<kbd>L</kbd> for left, down, up, or right. The remapper sends normal arrow-key
events, so the shortcut works system-wide rather than only inside an editor.

### Can I get Vim navigation system-wide on Linux?

Yes, if by “Vim navigation” you mainly mean HJKL arrow movement. A keyboard layer
is simpler than making every application modal: <kbd>Tab</kbd> + HJKL works in
browsers, terminals, menus, text fields, and other applications that accept
arrow keys.

### Why not use a full system-wide Vim mode?

Full Vim behavior needs concepts such as normal mode, insert mode, text objects,
and application-aware editing. For selecting a browser suggestion or recalling a
terminal command, that adds transitions without adding value. This setup solves
the smaller problem directly by relocating the existing arrow keys.

### Does the Tab key still work normally?

Yes. Tap Tab to send a normal Tab; hold it with another mapped key to activate
the navigation layer. The configs also account for common Tab shortcuts as noted
in the tap/hold section above.

### Does this work in browser URL bars and autocomplete menus?

Yes. Those interfaces already respond to arrow keys, and the layer emits ordinary
arrow events. For example, type `goo`, then use <kbd>Tab</kbd> + <kbd>J</kbd> to
move down through suggestions and <kbd>Tab</kbd> + <kbd>K</kbd> to move back up.

### Does this work in a terminal?

Yes. <kbd>Tab</kbd> + <kbd>K</kbd> sends Up to recall the previous command,
<kbd>Tab</kbd> + <kbd>J</kbd> sends Down, and <kbd>Tab</kbd> + <kbd>L</kbd> sends
Right to accept autocomplete behavior supported by your shell—without entering
and leaving a Vim editing mode.

### What is the difference between keyd, Kanata, and KMonad?

These files use **keyd** and **Kanata**. The advanced config may be easy to
misremember as KMonad because both tools use Lisp-like configuration, but the
actual tool here is Kanata. keyd is the easier choice for this small navigation
layer; Kanata powers the toggleable mouse layer.

### Can I use the keyboard as a mouse?

With the Kanata config, yes. Tap Right Shift to toggle mouse mode, use HJKL to
move, A/G/semicolon to click, and U/E to scroll. Tap Right Shift again or press
Escape to leave mouse mode.

### Will the Fn-lock light indicate mouse mode on every computer?

No. The included LED helper targets the Lenovo IdeaPad interface at
`/sys/bus/platform/devices/VPC2004:00/fn_lock`. Other devices need a different
hardware-specific indicator, but the keyboard mouse still works without one.

## Troubleshooting and emergency exits

- Validate before restarting: `keyd check keyd/default.conf` or
  `kanata --check --cfg kanata/kanata.kbd`.
- If keyd traps the keyboard because of a bad config, press
  <kbd>Backspace</kbd> + <kbd>Escape</kbd> + <kbd>Enter</kbd> to terminate it.
- Kanata's emergency exit is <kbd>Left Ctrl</kbd> + <kbd>Space</kbd> +
  <kbd>Escape</kbd>.
- If keys fire twice or behave strangely, make sure only one remapper is active.
- If Kanata cannot open input devices, confirm the new groups are active after a
  full logout/login and inspect `ls -l /dev/uinput`.
- If programming symbols are wrong, adapt the shifted symbol bindings for your
  keyboard layout; the supplied mappings assume US QWERTY.
- If the mouse works but its light does not, that is an indicator compatibility
  issue, not a Kanata mouse-layer failure.

## Files

```text
.
├── keyd/
│   └── default.conf
├── kanata/
│   ├── 99-input.rules
│   ├── 99-kanata-fnlock.rules
│   ├── fn-lock-indicator.py
│   ├── fn-lock-indicator.service
│   ├── kanata.kbd
│   └── kanata.service
└── README.md
```

The two main config files are snapshots of the working local setup. The included
Kanata user service avoids hard-coded usernames, while the optional LED helper
retains the original Lenovo-specific behavior.
