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
arch-chroot /mnt