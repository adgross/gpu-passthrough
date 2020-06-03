#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
        echo "run this script as root"
        exit 1
fi

# Stop display manager
systemctl stop display-manager.service

# remove the symlink to nvidia conf file
# so xorg don't reference the nvidia gpu
rm -f /etc/X11/xorg.conf.d/10-nvidia.conf

# Unbind the drivers from GPU
virsh nodedev-detach pci_0000_08_00_0
virsh nodedev-detach pci_0000_08_00_1

# Load VFIO Kernel Module
modprobe vfio-pci

sleep 2

# Start display manager
systemctl start display-manager.service
