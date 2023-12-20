#!/bin/bash

echo "Please ensure you have a backup of any important data before proceeding."
read -rp "Press Enter to continue or Ctrl+C to exit..."

# Keyboard layout and timezone
loadkeys hu
timedatectl set-timezone Europe/Budapest

# Partitioning
echo "Partition the disk:"
echo "1. Create 1GB EFI, 2. SWAP, 3. Remaining for root"
echo "Use 'cfdisk' or 'fdisk' to partition the disk."

# Ask for partition numbers
read -rp "Enter the EFI partition number (e.g., /dev/sda1): " efi_part
read -rp "Enter the SWAP partition number (e.g., /dev/sda2): " swap_part
read -rp "Enter the root partition number (e.g., /dev/sda3): " root_part

# Format and mount partitions
mkswap "/dev/$swap_part"
swapon "/dev/$swap_part"

mkfs.btrfs "/dev/$root_part"
mount "/dev/$root_part" /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

mount -o defaults,noatime,compress=zstd,ssd,subvol=@ "/dev/$root_part" /mnt
mkdir -p /mnt/home
mount -o defaults,noatime,compress=zstd,ssd,subvol=@home "/dev/$root_part" /mnt/home

mkfs.fat -F 32 "/dev/$efi_part"
mkdir -p /mnt/boot/efi
mount "/dev/$efi_part" /mnt/boot/efi

# Update mirrorlist
reflector --country Hungary --age 6 --sort rate --save /etc/pacman.d/mirrorlist

# Install base system
pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs nano base-devel

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF
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
EOF

echo "Installation completed. You can now reboot your system."
