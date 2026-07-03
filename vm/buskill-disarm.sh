#!/bin/bash

################################################################################
# File:    sys-usb:/usr/local/bin/buskill-disarm.sh
# Purpose: Temp disarm BusKill. For more info, see: https://buskill.in/qubes-os/
# Authors: Tom <humandecoded.io>
# Co-Auth: Michael Altfield <michael@buskill.in>
# Created: 2023-05-10
# License: GNU GPLv3
################################################################################

# replace the 'shutdown' trigger with the 'lock' trigger
sudo rm /etc/udev/rules.d/buskill.rules
sudo ln -s /rw/config/buskill.lock.rules /etc/udev/rules.d/buskill.rules
sudo udevadm control --reload

# let the user know that BusKill is now temporarily disarmed
notify-send -t 21000 "BusKill" "Disarmed for 30 seconds" -i changes-allow

# wait 30 seconds
sleep 30

# replace the 'lock' trigger with the 'shutdown' trigger
sudo rm /etc/udev/rules.d/buskill.rules
sudo ln -s /rw/config/buskill.rules /etc/udev/rules.d/buskill.rules
sudo udevadm control --reload
notify-send -t 5000 "BusKill" "BusKill is Armed" -i changes-prevent
