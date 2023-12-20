#!/bin/bash

ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc
nano /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=hu" >> /etc/vconsole.conf
echo "ArchLaptop" >> /etc/hostname
passwd
useradd -m -G wheel -s /bin/bash mate
passwd mate
EDITOR=nano visudo
nano /etc/pacman.conf
pacman -Sy
pacman -Sy --noconfirm linux-headers sof-firmware grub efibootmgr networkmanager network-manager-applet acpi acpi_call tlp acpid dialog reflector bluez bluez-utils cups pipewire pipewire-jack pipewire-pulse grub-btrfs git mesa nvidia-dkms nvidia-settings nvidia-utils lib32-nvidia-utils
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager bluetooth cups.service tlp acpid

exit