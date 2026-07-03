# BusKill for QubesOS (Contrib Package)

BusKill is a laptop kill cord. It's a USB cable with a magnetic breakaway
that you attach to your body and connect to your computer. If the connection
is severed, your device will lock, shutdown, or shred its LUKS encryption
keys — keeping your encrypted data safe from thieves.

This repository contains the QubesOS contrib package for BusKill, allowing
you to install BusKill on QubesOS with a single command.

## Quick Install

On a fresh install of QubesOS, run:

```bash
sudo qubes-dom0-update buskill-dom0
```

Then configure sys-usb:

```bash
sudo /usr/lib/qubes-buskill/buskill-postinstall.sh configure
```

If your sys-usb uses a Fedora or Debian-based TemplateVM, also install the
VM package in that template:

```bash
# In your sys-usb TemplateVM:
sudo dnf install buskill-vm     # Fedora-based
# OR
sudo apt install buskill-vm     # Debian-based
```

Then restart sys-usb for the udev rules to take effect.

## What This Package Does

### dom0 Package (buskill-dom0)

Installed via `qubes-dom0-update`. This package:

1. Installs **qrexec service scripts** to `/etc/qubes-rpc/`:
   - `buskill.lock` — locks the screen via xscreensaver
   - `buskill.softShutdown` — shuts down the computer
   - `buskill.hardReboot` — immediately reboots (via SysRq)
   - `buskill.selfDestruct` — shreds LUKS headers and shuts down

2. Installs **qrexec policy files** to `/etc/qubes-rpc/policy/` that permit
   `sys-usb` to execute the above triggers in dom0.

3. Installs the **post-install script** at
   `/usr/lib/qubes-buskill/buskill-postinstall.sh` which:
   - Copies udev rules to `sys-usb:/rw/config/`
   - Copies the disarm script to `sys-usb:/usr/local/bin/`
   - Configures `sys-usb:/rw/config/rc.local` to persist the rules
   - Sets up the keyboard shortcut Ctrl+Shift+D to disarm BusKill

### VM Package (buskill-vm)

Installed in the TemplateVM used by your sys-usb qube. This package:

1. Installs **udev rules** to `/etc/udev/rules.d/70-buskill.rules`
2. Installs **support files** to `/usr/lib/qubes-buskill/vm/`

## What Happens After Install

### Default Trigger: Lock Screen

By default, removing any USB device from sys-usb will **lock your screen**.

If you want to change this behavior, see the [Customization](#customization)
section below.

### Keyboard Shortcut: Ctrl+Shift+D

The keyboard shortcut **Ctrl+Shift+D** runs `qvm-run sys-usb buskill-disarm.sh`,
which temporarily swaps BusKill to a "lock only" trigger for 30 seconds.
This allows you to step away from your computer (e.g., for a bathroom break)
without triggering a shutdown.

## Customization

To change between the lock screen, soft shutdown, hard reboot, and
self-destruct triggers, edit the `buskill.rules` file on sys-usb:

```bash
qvm-run sys-usb "sudo nano /rw/config/buskill.rules"
```

Uncomment the trigger you want and comment-out the others:

```
# Lock screen (default):
#ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/bin/qrexec-client-vm dom0 buskill.lock"

# Soft shutdown (uncomment this to enable):
ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/bin/qrexec-client-vm dom0 buskill.softShutdown"

# Hard reboot:
#ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/bin/qrexec-client-vm dom0 buskill.hardReboot"

# Self-destruct (requires --yes):
#ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/bin/qrexec-client-vm dom0 buskill.selfDestruct+--yes"
```

After editing, reload udev:

```bash
qvm-run sys-usb "sudo udevadm control --reload"
```

## Uninstall

To completely remove BusKill from QubesOS:

```bash
# Clean up sys-usb configuration
sudo /usr/lib/qubes-buskill/buskill-postinstall.sh remove

# Remove the dom0 package
sudo qubes-dom0-update remove buskill-dom0

# Remove the VM package (in your sys-usb TemplateVM)
sudo dnf remove buskill-vm     # Fedora-based
# OR
sudo apt remove buskill-vm     # Debian-based
```

## Disclaimer

**WARNING: The self-destruct trigger is designed to cause PERMANENT, COMPLETE,
AND IRREVERSIBLE DATA LOSS.** It overwrites your LUKS headers with random
data, making all data on your encrypted partitions permanently inaccessible —
even with the correct passphrase.

Only enable the self-destruct trigger if you fully understand the risks and
are prepared for the possibility of accidental data loss. Test your
configuration thoroughly before depending on it.

The BusKill project and its contributors are not responsible for any data
loss that may occur as a result of using this software.

## Repository Layout

```
buskill-qubes-contrib/
├── .qubesbuilder                 # Qubes builder configuration
├── Makefile                      # install-dom0 / install-vm targets
├── README.md                     # This file
├── version                       # Upstream version (1.0.0)
├── rel                           # Package release number (1)
├── qubes-rpc/                    # qrexec service scripts for dom0
│   ├── buskill.lock
│   ├── buskill.softShutdown
│   ├── buskill.hardReboot
│   └── buskill.selfDestruct
├── qubes-rpc-policy/             # qrexec policy files for dom0
│   ├── buskill.lock
│   ├── buskill.softShutdown
│   ├── buskill.hardReboot
│   └── buskill.selfDestruct
├── vm/                           # VM-side files for sys-usb
│   ├── 70-buskill.rules          # udev rules (for /etc/udev/rules.d/)
│   ├── buskill.rules             # udev rules (for /rw/config/)
│   ├── buskill.lock.rules        # Lock-only udev rules (for disarm)
│   └── buskill-disarm.sh         # Temporary disarm script
├── dom0/
│   └── buskill-postinstall.sh    # Post-install configuration script
├── rpm_spec/
│   ├── buskill-dom0.spec.in      # RPM spec for dom0 package
│   └── buskill-vm.spec.in        # RPM spec for VM package
└── debian/                       # Debian packaging for VM package
    ├── changelog
    ├── compat
    ├── control
    ├── copyright
    ├── qubes-buskill.install
    ├── rules
    └── source/
        └── format
```

## Building

This package is built with [qubes-builderv2](https://github.com/QubesOS/qubes-builderv2).
See [Package Contributions](https://doc.qubes-os.org/en/latest/developer/general/package-contributions.html)
for the full guide.

## License

The code in this repository is licensed under the **GNU General Public License
v3.0** (GPLv3). See the [LICENSE](LICENSE) file for details.

The documentation and non-code content in this repository is licensed under
the **Creative Commons Attribution-ShareAlike 4.0 International** (CC BY-SA 4.0)
license.

Copyright 2020-2026 Michael Altfield <michael@buskill.in>
