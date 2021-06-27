#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "run this script as root"
    exit 1
fi

# Stop display manager
systemctl stop display-manager.service

# Unload VFIO-PCI Kernel Driver
modprobe -r vfio-pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

# recreate the symlink to nvidia conf file
ln -sf /etc/X11/xorg.conf.avail/10-nvidia.conf /etc/X11/xorg.conf.d/10-nvidia.conf

# Re-Bind GPU to Nvidia Driver
virsh nodedev-reattach pci_0000_08_00_1
virsh nodedev-reattach pci_0000_08_00_0

sleep 1

# Start Display Manager
systemctl start display-manager.service

