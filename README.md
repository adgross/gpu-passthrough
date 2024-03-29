# VFIO - GPU Passthrough

This is an example of VFIO usage with Nvidia GTX 1080 and ATI Radeon 5450.  
Iam assuming Xorg usage. Not tested under Wayland.  
Based on [ArchWiki][archwiki] how-to for gpu passthrough.


## Use case
Possibility to activate the gpu passthrough when needed. You may want to use the primary GPU for the host or don't need the guest running all the time, like when you don't need the gpu passthrough to play some _Windows-only_  game.

This use case have two states:  
1) no guest running &rarr; host use the monitors connect to all gpus;  
2) guest running &rarr; host use the secondary monitors and the guest use the primary monitors.


## Tested Hardware
* **CPU**: **AMD FX-8350**
* **GPU** _primary slot_: **AMD HD 5450**
* **GPU** _some secondary slot_: **Gigabyte NVIDIA GTX 1080 Windforce OC** ( _passthrough_ )
* **Motherboard**: **ASUS CROSSHAIR V FORMULA-Z** (BIOS version: 2201)
* RAM: 32GB
* Monitors: at least 2
    * 1 for host, connected to AMD HD 5450 
    * 1 for guest, connected to NVIDIA GTX 1080
* The *boot cmdline* used for this machine and configuration:
> _BOOT_IMAGE=/vmlinuz-linux root=/dev/mapper/main-root rw loglevel=3 quiet apparmor=1 lsm=lockdown,yama,apparmor,bpf_ amd_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=12

## Improve general usage
* If you have a ton of RAM and don't need it _always_ on the host, use [Static Huge Pages][archwiki static huge pages] for better performance.
* If your VM still using a NVIDIA driver prior to version 465, need changes to fix [error 43][archwiki error43].
* Control mouse and keyboard with [evdev][archwiki evdev].
    * The mouse/keyboard swap between host and guest is simple as *LCtrl + RCtrl*.
* Control mouse and keyboard using [Barrier][git barrier].
    * with this method it is recommended to have a virtio interface (NAT or isolated network), some _fast_ host<->guest network.
    * you can configure hotkeys to execute on host when pressed inside the guest, for example, push-to-talk applications running on host while playing a game on guest.
* Audio using Virtual Sound Card - [scream][git scream].
    * configure one [IVSHMEN][git scream ivshmem].
    * install the driver on Windows guest.
    * run the scream receiver on host.
    * [more info][archwiki scream]
* Audio using 5.1 [usb-audio][archwiki usb-audio]
* You can use the [MSI utility v3][app msi] to ensure [MSI][msi] for virtualized devices are working, checking if IRQs are negative.
* On this example, the VM have 2 disks, one as LVM's LV and another as raw image for demonstrative purposes. Usage of LVM allow us to snapshot, even with *raw* format, and is prefered.


## About the example configuration
* **win10.xml** = VM settings with GPU Passthrough.
* **win10-spice.xml** = I made this configuration to be able to modify the same VM without the need of GPU passthrough, **using spice**.
* **nvidia_to_guest.sh** = _script to enable_ vfio module
* **nvidia_to_host.sh** = _script to disable_ vfio module


The systemctl start/stop is **required** because xorg need to be restarted to unbind the nvidia modules.  
_If needed_, we can use this time while xorg is not started to change the configuration files, to ensure the system will works without the Passthrough GPU. On both scripts I manipulate the 10-nvidia.conf symbolic link, so we have:

* host with both GPUs &rarr; /etc/X11/xorg.conf.d/**{10-nvidia.conf**, **20-radeon.conf}**
* host running GPU Passthrough &rarr; /etc/X11/xorg.conf.d/**20-radeon.conf**

You may need a similar setup if xorg can't autodetect the GPUs and displays in both states (with and without GPU passthrough).


## If xorg need .conf files, how create the setup
  1. Write down the xorg ".conf" files that works for you with both GPUs. Think on this as the [1)](#use-case) "xorg without guest" state
  2. Stop the display-manager service
  3. Load the vfio module in the passthrough GPU using the virsh command, use your PCI address got from lspci (08:00.0 and 08:00.1 in this example).
> virsh nodedev-detach pci_0000_08_00_0  
> virsh nodedev-detach pci_0000_08_00_1
  4. Create the needed xorg configuration for your secondary GPU only.
  5. Now create scripts that recreate both states.  
You can check both ***nvidia_to_guest*** and ***nvidia_to_host*** scripts, notice the usage of symbolic link, given this simplifies ***a lot*** this setup.
  6. Run the scripts when you want to passthrough the GPU or return to host  
There are many ways to run both scripts, I prefer manual execution, like:  
    * 1) Using GNU Screen / tmux  
    * 2) Go to another tty _(ex: Ctrl + Alt + F2)_ and run from there.  
    * The script need to survive the display-manager restart

## Workflow - Common usage

0. Note: I run both scripts inside a tmux session.
1. We run nvidia_to_guest.sh as root or sudo.
    * this will kill every process depending on xorg.
2. Display manager should restart, we login again.
3. Start the GPU Passthrough VM (you can use virt-manager).
4. VM is running... do whatever you want.
    * use evdev / Barrier / ... to control host and guest.
5. Shutdown the VM.
6. Run nvidia_to_host.sh as root or sudo.
    * this will kill every process depending on xorg.
7. We back again to start, with both gpus for the host.


## Troubleshooting

#### If the system crash while running the VM and we are forced to reboot.
When you need to change xorg configuration files between "no pci passthrough" and "pci passthrough" state, in the first boot after the crash, nvidia modules will load, but xorg will not use the Nvidia GPU because there is no '.conf' file that wants it. To fix, simple run the `nvidia_to_host.sh` script.

[git barrier]: https://github.com/debauchee/barrier/
[git scream]: https://github.com/duncanthrax/scream/
[app msi]: https://forums.guru3d.com/threads/windows-line-based-vs-message-signaled-based-interrupts-msi-tool.378044/
[msi]: https://vfio.blogspot.com/2014/09/vfio-interrupts-and-how-to-coax-windows.html
[git scream ivshmem]: https://github.com/duncanthrax/scream/#using-ivshmem-between-windows-guest-and-linux-host
[archwiki]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
[archwiki static huge pages]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Static_huge_pages
[archwiki error43]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Video_card_driver_virtualisation_detection
[archwiki evdev]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev
[archwiki scream]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_VM_audio_to_host_via_Scream
[archwiki usb-audio]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_VM_audio_to_host_via_PulseAudio