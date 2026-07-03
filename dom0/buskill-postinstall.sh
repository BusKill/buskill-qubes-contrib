#!/bin/bash

################################################################################
# File:    dom0:/usr/lib/qubes-buskill/buskill-postinstall.sh
# Purpose: Post-install configuration for BusKill on QubesOS.
#          Configures sys-usb and sets up keyboard shortcuts.
#          For more info, see: https://buskill.in/qubes-os/
# Authors: Michael Altfield <michael@buskill.in>
# Created: 2026-07-03
# License: GNU GPLv3
################################################################################

set -e

BUSKILL_USR_DIR="/usr/lib/qubes-buskill"

########################################
# CONFIGURE SYS-USB                    #
########################################

configure_sys_usb() {
    local sys_usb_vm="sys-usb"

    # Check if sys-usb exists
    if ! qvm-check "${sys_usb_vm}" 2>/dev/null; then
        echo "WARNING: ${sys_usb_vm} not found. Skipping sys-usb configuration."
        echo "If you use a different USB qube, manually copy the files from"
        echo "${BUSKILL_USR_DIR}/vm/ to your USB qube's /rw/config/."
        return 0
    fi

    echo "Configuring ${sys_usb_vm}..."

    # Ensure sys-usb is running
    if ! qvm-check --running "${sys_usb_vm}" 2>/dev/null; then
        echo "Starting ${sys_usb_vm}..."
        qvm-start "${sys_usb_vm}" --skip-if-running
        sleep 5
    fi

    # Copy buskill.rules to sys-usb's /rw/config/
    echo "Installing buskill.rules..."
    qvm-run --pass-io "${sys_usb_vm}" "sudo tee /rw/config/buskill.rules" < "${BUSKILL_USR_DIR}/vm/buskill.rules"

    # Copy buskill.lock.rules to sys-usb's /rw/config/
    echo "Installing buskill.lock.rules..."
    qvm-run --pass-io "${sys_usb_vm}" "sudo tee /rw/config/buskill.lock.rules" < "${BUSKILL_USR_DIR}/vm/buskill.lock.rules"

    # Copy buskill-disarm.sh to sys-usb
    echo "Installing buskill-disarm.sh..."
    qvm-run --pass-io "${sys_usb_vm}" "sudo tee /usr/local/bin/buskill-disarm.sh" < "${BUSKILL_USR_DIR}/vm/buskill-disarm.sh"
    qvm-run "${sys_usb_vm}" "sudo chmod +x /usr/local/bin/buskill-disarm.sh"

    # Add rc.local entry to persist udev rules across reboots
    echo "Adding rc.local entry..."
    qvm-run "${sys_usb_vm}" 'grep -q "buskill" /rw/config/rc.local 2>/dev/null || echo -e "\n# BusKill: symlink udev rules and reload\nsudo ln -sf /rw/config/buskill.rules /etc/udev/rules.d/buskill.rules\nsudo udevadm control --reload" | sudo tee -a /rw/config/rc.local'
    qvm-run "${sys_usb_vm}" "sudo chmod +x /rw/config/rc.local"

    # Apply configuration immediately
    echo "Applying udev rules..."
    qvm-run "${sys_usb_vm}" "sudo ln -sf /rw/config/buskill.rules /etc/udev/rules.d/buskill.rules"
    qvm-run "${sys_usb_vm}" "sudo udevadm control --reload"

    echo "sys-usb configuration complete."
}

########################################
# SETUP KEYBOARD SHORTCUT              #
########################################

setup_keyboard_shortcut() {
    echo "Setting up keyboard shortcut (Ctrl+Shift+D)..."

    local xfce_config="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"

    mkdir -p "$(dirname "${xfce_config}")"

    # Add the shortcut if it doesn't exist
    if [ -f "${xfce_config}" ]; then
        grep -q "buskill-disarm" "${xfce_config}" 2>/dev/null || \
        sed -i 's|</channel>|<property name="&lt;Primary&gt;&lt;Shift&gt;d" type="string" value="qvm-run sys-usb buskill-disarm.sh"/>\n</channel>|' "${xfce_config}"
    else
        cat > "${xfce_config}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="default" type="empty">
      <property name="&lt;Primary&gt;&lt;Shift&gt;d" type="string" value="qvm-run sys-usb buskill-disarm.sh"/>
    </property>
  </property>
</channel>
EOF
    fi

    echo "Keyboard shortcut configured. Please log out and back in for changes to take effect."
}

########################################
# MAIN                                 #
########################################

case "${1:-}" in
    configure)
        configure_sys_usb
        setup_keyboard_shortcut
        ;;
    remove)
        echo "Cleaning up BusKill configuration..."
        if qvm-check sys-usb 2>/dev/null; then
            qvm-run sys-usb "sudo rm -f /etc/udev/rules.d/buskill.rules /etc/udev/rules.d/buskill.lock.rules"
            qvm-run sys-usb "sudo udevadm control --reload"
        fi
        rm -f "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml.bak"
        echo "Cleanup complete."
        ;;
    *)
        echo "Usage: $0 {configure|remove}"
        exit 1
        ;;
esac
