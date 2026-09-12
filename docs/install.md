# Installation and maintenance

Run commands from the repository root unless a step says otherwise. The main
setup uses a system keyd daemon and a system Kanata mouse daemon. It works before
login and does not require granting your login user access to input devices.

## 1. Install dependencies

Use your distribution's packages or the upstream instructions:

- [keyd installation](https://github.com/rvaiya/keyd#installation)
- [Kanata releases](https://github.com/jtroo/kanata/releases) or
  [Linux setup](https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md)

The supplied configs were tested with keyd 2.6.0 and Kanata 1.11.0. Older versions
may not support the configuration syntax. Validate before activation.

The scripts require Bash, GNU coreutils (`timeout`, `stdbuf`, `install`, etc.),
awk, and systemd. Python 3 is only needed for the optional indicator.

For the system mouse service, Kanata must be available as `/usr/local/bin/kanata`
or `/usr/bin/kanata`. If you installed it using Cargo:

```bash
cargo install kanata
# Back up an existing /usr/local/bin/kanata before replacing it.
sudo install -Dm755 "$HOME/.cargo/bin/kanata" /usr/local/bin/kanata
```

Load uinput if it is not already available:

```bash
sudo modprobe uinput
ls -l /dev/uinput
```

If your distribution does not load it automatically on reboot, add a file in
`/etc/modules-load.d/` containing `uinput`. The system services run as root;
the main path does not need `99-input.rules` or input/uinput group membership.

## 2. Validate and stage files

```bash
bash scripts/check.sh
bash scripts/install.sh --dry-run
sudo bash scripts/install.sh
```

For keyboard mappings only, use `--keyboard-only` for all three commands.
Kanata is not required in that mode.

The installer:

- Validates the configs before copying.
- Saves existing destination files, retaining their paths, in a unique
  `/var/backups/home-row-navigation.*` directory and prints that location.
- Installs `/etc/keyd/default.conf`.
- In full mode, also installs `/etc/kanata/home-row-navigation.kbd` and
  `/etc/systemd/system/home-row-navigation-mouse.service`.
- Runs `systemctl daemon-reload`, but does not start, stop, restart, reload, or
  enable either remapper.
- Refuses additional `/etc/keyd/*.conf` files because they could override the
  output exclusion. Merge your custom config manually if needed.

Save the printed backup path. If a file copy fails, already-copied files remain
staged; restore them from that backup before restarting any remapper.

The installer does not alter old service units, their overrides, desktop
settings, permission rules, or optional indicators.

## 3. Migrate an existing setup

Skip this section on a fresh installation.

Do not run two Kanata instances or let old keyd and all-in-one Kanata configs
grab the same physical keyboard. Inspect the services you already use:

```bash
systemctl status keyd kanata home-row-navigation-mouse --no-pager
systemctl --user status kanata --no-pager
```

If present, disable the old Kanata service in its actual scope:

```bash
# Run the applicable command(s); a "unit not found" means that scope is unused.
sudo systemctl disable --now kanata.service
systemctl --user disable --now kanata.service
```

If you ran Kanata directly from a terminal or another supervisor, stop that
instance too. Do not stop your desktop session.

The new system service has a distinct name and reads
`/etc/kanata/home-row-navigation.kbd`. Old `kanata.service.d` overrides pointing
to a home-directory config will not affect it. Leave old files in place for
rollback, but keep the old service disabled.

If your optional indicator was previously called
`kanata-capslock-indicator.service`, it can keep working: the TCP address and
`mouse` layer name are unchanged. Do not install a second indicator alongside it.

### Keeping an existing service instead

You can retain a working system service instead of adopting the new one:
back up and copy `kanata/kanata.kbd` to the config path in its `ExecStart`,
install the keyd config, then install `kanata/keyd-ordering.conf` as a system
service drop-in. Validate the exclusion and configs before restarting it.
Do not also enable `home-row-navigation-mouse.service`.
Inspect `systemctl cat kanata` to confirm the path and overrides.

## 4. Check routing before enabling mouse support

Skip to activation for keyboard-only mode. For full mode, verify the actual
Kanata output ID with keyd stopped. This avoids a feedback loop if the output
ID differs from the supplied config.

First stop the main daemons (ignore a missing mouse unit on a new install):

```bash
sudo systemctl stop home-row-navigation-mouse.service keyd.service
```

In **terminal A**, run a temporary Kanata probe:

```bash
sudo env PATH=/usr/local/bin:/usr/bin:/bin kanata \
  --cfg /etc/kanata/home-row-navigation.kbd --no-wait
```

It creates a virtual output device and waits for `keyd virtual keyboard`.
It does not grab the physical keyboard. No control-server port is opened by
this probe.

In **terminal B**, run:

```bash
sudo bash scripts/check-device-id.sh /etc/keyd/default.conf
```

Expected on the tested version:

```text
PASS: /etc/keyd/default.conf excludes Kanata output 0001:0001:0e03123f
```

If it reports a missing exclusion, edit `/etc/keyd/default.conf` and the repo's
`keyd/default.conf` so `[ids]` contains `-<the reported full ID>`. Re-run the
check. Never replace it with the short `-0001:0001`: that would also exclude
many physical keyboards.

Stop the probe with **Ctrl+C in terminal A** before activating the services.

Repeat this check after changing Kanata's version, output name, or device
capabilities. Device IDs are not assumed to be portable between arbitrary builds.

## 5. Activate

Keyboard only:

```bash
sudo systemctl enable --now keyd.service
sudo keyd reload
```

Keyboard plus mouse:

```bash
sudo systemctl enable --now keyd.service home-row-navigation-mouse.service
sudo keyd reload
```

Inspect status and routing:

```bash
systemctl status keyd home-row-navigation-mouse --no-pager
sudo journalctl -b -u keyd -u home-row-navigation-mouse --no-pager -n 80
```

keyd should match your physical keyboard and **ignore `kanata`**. Kanata should
register **only `keyd virtual keyboard`**. Its config allows startup before the
virtual keyboard appears and reconnects after device recreation.

Try the actual behavior in a text field:

1. Tap Caps: Escape. Hold Caps alone beyond 200 ms: no Escape.
2. Caps + A: Ctrl+A.
3. Tab + H/J/K/L: arrows; Tab alone: Tab.
4. Tab + Caps, type letters, then Tab + Caps again: Caps Lock on/off.
5. Tap Right Shift, move with H/J/K/L, then tap Right Shift again to exit.

## KDE: actual Caps Lock does not toggle

A desktop option can reinterpret the Caps Lock keycode emitted by keyd.
In KDE Keyboard settings, remove Caps-specific overrides such as “Caps Lock
chooses the third level” or “Caps Lock is another Ctrl,” and click Apply.
Retain unrelated layout and modifier options.

If editing `~/.config/kxkbrc` directly, first back it up and remove only the
conflicting items from `[Layout]` → `Options`. An empty `Options=` is appropriate
only if you want no XKB options. A generic KWin reconfigure or the older
`KeyboardLayouts.reloadConfig` signal may leave the old keymap loaded.

On the tested Plasma version, notify its configuration watcher:

```bash
gdbus emit --session --object-path /kxkbrc \
  --signal org.kde.kconfig.notify.ConfigChanged \
  "{'Layout': [b'Options']}"
```

Allow a moment for the notification to be processed. If XWayland and
`xkbcomp` are available, inspect the exported loaded keymap:

```bash
xkbcomp -xkb "$DISPLAY" - 2>/dev/null | sed -n '/key <CAPS>/,+5p'
```

It should map to `Caps_Lock`, not `ISO_Level3_Shift` or `Control_L`.
Verify with actual typing too. Logging out and back in is a fallback if your
desktop version does not support this notification. Other desktops may have
their own Caps options; the installer deliberately does not change them.

## Updates and disabling mouse mode

After editing repo configs:

```bash
bash scripts/check.sh
sudo bash scripts/install.sh
# Recheck the device exclusion first if Kanata's output identity changed.
sudo systemctl restart home-row-navigation-mouse.service
sudo keyd reload
```

Use `--keyboard-only` for keyboard-only installations and omit the mouse restart.
For keyboard-only edits on a full installation, staging with
`--keyboard-only` and running `sudo keyd reload` is sufficient.

To temporarily use keyboard mappings alone:

```bash
sudo systemctl disable --now home-row-navigation-mouse.service
```

keyd remains active. To restore mouse mode:

```bash
sudo systemctl enable --now home-row-navigation-mouse.service
```

If you retained a legacy service, use its actual name and scope instead.

## Optional Lenovo Fn-lock indicator

Only use this if the following hardware interface exists:

```bash
test -e /sys/bus/platform/devices/VPC2004:00/fn_lock
```

Install permission and helper files (back up any existing files first):

```bash
getent group input >/dev/null || sudo groupadd --system input
sudo usermod -aG input "$USER"
sudo install -Dm644 kanata/99-kanata-fnlock.rules \
  /etc/udev/rules.d/99-kanata-fnlock.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=platform

install -Dm755 kanata/fn-lock-indicator.py ~/.config/kanata/fn-lock-indicator.py
install -Dm644 kanata/fn-lock-indicator.service \
  ~/.config/systemd/user/fn-lock-indicator.service
```

Log out and back in for group membership to take effect, then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now fn-lock-indicator.service
```

The helper reconnects to `127.0.0.1:5829`; its user service does not start a
second Kanata instance. It controls real Fn-lock state, including function-key
behavior. Membership in `input` can also grant access to input devices;
the main remapper setup does not require this membership.

## Alternative: run Kanata as a user service

Use either this path or the main system mouse service, never both. keyd still
runs as a system service.

Follow the [upstream Linux permissions guide](https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md)
to create the `input`/`uinput` groups if absent, add your user, install
`kanata/99-input.rules`, load uinput, and reload udev rules. Log out/in and
confirm access to the keyboard device and `/dev/uinput`.

Back up existing destinations, then:

```bash
install -Dm644 kanata/kanata.kbd ~/.config/kanata/kanata.kbd
install -Dm644 kanata/kanata.service ~/.config/systemd/user/kanata.service
kanata --check --cfg ~/.config/kanata/kanata.kbd
```

Verify the output exclusion as in step 4, using the user config for the probe.
Keep the main system mouse service disabled. Activate:

```bash
sudo systemctl enable --now keyd
systemctl --user daemon-reload
systemctl --user enable --now kanata.service
```

The supplied user service searches the user's Cargo bin directory as well as
system paths. A user unit cannot order itself after a system unit; Kanata waits
for the virtual keyboard instead. Its config is now under your home directory,
so subsequent updates must copy to that path, not the main installer's `/etc` path.

## Troubleshooting

- Config errors: run `bash scripts/check.sh` before installation.
- Repeated keys or a loop: stop both daemons and recheck the full output ID and
  input-name filter. Check for extra keyd configs and duplicate Kanata instances.
- Mouse daemon running but no mouse: check logs for registration of
  `keyd virtual keyboard`. Confirm keyd is active.
- Right Shift does not toggle: release it within 200 ms without another key.
- Caps Lock output exists but lowercase typing continues: inspect the desktop's
  loaded keymap, not only its on-disk settings.
- Wrong symbols: adapt the symbol bindings for your keyboard layout.
- Mouse works without a light: the optional indicator is hardware-specific.

keyd's emergency sequence is **Backspace + Escape + Enter**. Kanata's is
**Left Ctrl + Space + Escape**, evaluated on its input (keyd's output in this
chain). Service restart policies may restart an exited daemon; from another
terminal/TTY, stop the services explicitly:

```bash
sudo systemctl stop home-row-navigation-mouse.service keyd.service
```

## Rollback

The installer prints its backup directory. No automatic rollback is claimed.
Restore only the files present in that specific backup.

1. Stop the new mouse service and keyd.
2. Copy saved files back from their retained paths under the backup directory.
   For example, restore `BACKUP/etc/keyd/default.conf` to
   `/etc/keyd/default.conf`.
3. If a newly installed mouse unit/config had no prior version, disable the
   mouse service and move those specific files into the backup directory.
4. Run `sudo systemctl daemon-reload`.
5. Re-enable/start the services used before migration, using their original
   configs and scopes. Keep the new mouse service disabled if restoring the
   old Kanata setup.

For example, with your actual backup path substituted:

```bash
sudo systemctl disable --now home-row-navigation-mouse.service
sudo systemctl stop keyd.service
sudo cp -a /var/backups/home-row-navigation.EXAMPLE/etc/keyd/default.conf \
  /etc/keyd/default.conf
sudo systemctl daemon-reload
```

If returning to an old all-in-one Kanata setup, leave keyd stopped/disabled and
start the old Kanata service. Restore any desktop settings from your separate
desktop-config backup if desired; the installer did not change them.
