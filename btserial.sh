#!/bin/bash -e

# Taken from the following:
# Headless Raspberry Pi configuration over Bluetooth by Patrick Hundal
# https://hacks.mozilla.org/2017/02/headless-raspberry-pi-configuration-over-bluetooth/
#
# Edit the display name of the RaspberryPi so you can distinguish
# your unit from others in the Bluetooth console
# (very useful in a class setting)

echo PRETTY_HOSTNAME=raspberrypi-01 > /etc/machine-info

# Edit /lib/systemd/system/bluetooth.service to enable BT services
sudo sed -i: 's|^Exec.*toothd$| \
ExecStart=/usr/lib/bluetooth/bluetoothd -C \
ExecStartPost=/usr/bin/sdptool add SP \
ExecStartPost=/bin/hciconfig hci0 piscan \
|g' /lib/systemd/system/bluetooth.service

# create /etc/systemd/system/rfcomm.service to enable
# the Bluetooth serial port from systemctl
sudo cat <<EOF | sudo tee /etc/systemd/system/rfcomm.service > /dev/null
[Unit]
Description=RFCOMM service
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/rfcomm watch hci0 1 getty rfcomm0 115200 xterm

[Install]
WantedBy=multi-user.target
EOF

# enable the new rfcomm service
sudo systemctl enable rfcomm

# start the rfcomm service
sudo systemctl restart rfcomm

# end of script
