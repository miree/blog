# ArchLinux guide

## Installation

https://wiki.archlinux.org/title/Installation_guide

This is how to install on a DELL Wyse3040 thin client (8 GB storage, 2 GB ram) 

In order to clear the BIOS password, the PC has to be powered on while the clear button (next to the battery on the PCB) is hold down.

### Disk formatting

After booting the ArchLinux ISO image, first show the available disks
  - run `lsblk`, output is something like this:
```
lsblk
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0          7:0    0 824.9M  1 loop /run/archiso/airootfs
sda            8:0    1  29.3G  0 disk
|-sda1         8:1    1   999M  0 part /run/archiso/bootmnt
|-sda2         8:2    1   180M  0 part
mmcblk0      179:0    0   7.3G  0 disk
|-mmcblk0p1  179:1    0 1023.9M 0 part
|-mmcblk0p2  179:2    0      1G 0 part
|-mmcblk0p3  179:3    0      1G 0 part
|-mmcblk0p4  179:4    0    512M 0 part
mmcblk0boot0 179:8    0      4M 1 disk
mmcblk0boot1 179:16   0      4M 1 disk
```
  - `fdisk /dev/mmcblk0`
    - Press `p` to see the existing partition layout.
    - Delete all partitions by pressing `d` until all partitions are gone.
    - Press `n` to create a new partition. 
    - Size `+512M`
    - Change type of partition to EFI by pressing `t` and then `1` 
    - Press `n` to crate the main Linux partition, use the entierty of the remaining disk by accepting the default size suggestions.
    - Press `p` to see the layout
    - Press `w` to write changes to disk

### Create filesystems 

  - `mkfs.ext4 /dev/mmcblk0p2`
  - `mkfs.fat -F 32 /dev/mmcblk0p1`
  - `mount         /dev/mmcblk0p2 /mnt`
  - `mount --mkdir /dev/mmcblk0p1 /mnt/boot`

### Install base system

  - `pacstrap -K /mnt base linux linux-firmware`
  - `genfstab -U /mnt >> /mnt/etc/fstab`
  - `arch-chroot /mnt`

### System setup

  - `pacman -S vim` 
  - `ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime`
  - `hwclock --systohc`
  - `vim /etc/locale.gen` uncomment `en_US.UTF-8` and `en_US`
  - `locale-gen`
  - `echo LANG=en_US.UTF-8 > /etc/locale.conf`
  - `echo wyse3040arch3 > /etc/hostname`
  - `passwd` to set root password

### Bootloader setup

  - `bootctl install`
  - `vim /boot/loader/loader.conf` edit that it looks like this:
```
timeout 10
default arch-*
```
  - `vim /boot/loader/entries/arch.conf` edit that it looks like this:
```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/mmcblk0p2 rw
``` 

### Network Manager setup

  - `pacman -S networkmanager openssh` 
  - `systemctl enable NetworkManager`
  - `systemctl enable sshd`

### Reboot
  - `exit`  
  - `umount -R /mnt`
  - `reboot` 
  - Remove the USB stick with the ArchLinux installer.
  - should reboot. login as root

### Create normal user with sudo

  - `useradd -m -G wheel,users newusername`
  - `passwd newusername`
  - `pacman -S sudo`
  - `EDITOR=vim visudo` uncomment the line `%wheel ALL=(ALL:ALL) ALL`
  - `exit`
  - login as newusername

### X11 
  - `sudo pacman -S xorg-server xfce4 xf86-video-intel`
  - `cp /etc/X11/xinit/xinitrc $HOME/.xinitrc`
  - `vim $HOME/.xinitrc` 
    - add `exec startxfce4` at the end of that file
    - comment/remove the other lines at the end (`twm`, `xterm`)
  - startx


