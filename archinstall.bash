#! /bin/bash
# My Archlinux install script
# Features :
#  - btrfs file system
#  - disk encryption with luks

### Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease run this script as root\e[0m"
    exit
fi

### Config options
fdisk -l
read -p "Select installation disk (/dev/sda) : " target
# Username prompt
read -p "Enter username (tux) : " username
# Hostname prompt
read -p "Enter hostname (archlinux) : " hostname
# Locale prompt
read -p "Enter locale (fr_FR.UTF-8) : " locale
# Keymap prompt
read -p "Enter keymap (fr) : " keymap
# Timezone prompt
read -p "Enter timezone (Europe/Paris) : " timezone

# Default
username=${username:-"tux"}
hostname=${hostname:-"archlinux"}
locale=${locale:-"fr_FR.UTF-8"}
keymap=${keymap:-"fr"}
timezone=${timezone:-"Europe/Paris"}
rootmnt="/mnt"

### Packages to pacstrap ##
pacstrappacs=(
    # Base
    base
    linux-zen
    linux-zen-firmware
    # File System tools
    btrfs-progs	# BTRFS
    e2fsprogs	# extX
    dosfstools	# FAT
    cryptsetup	# encryption tools
    # Manuel
    man-db
    man-pages-fr
    # Text Editor
    nano
    vi
    # NetworkManager
    networkmanager
    )

# Partition
echo "Creating partitions..."
sgdisk -Z "$target"
sgdisk \
    -n1:0:+512M  -t1:ef00 -c1:EFISYSTEM \
    -N2          -t2:8304 -c2:linux \
    "$target"

# Reload partition table
sleep 2
partprobe -s "$target"
sleep 2

# Encrypt the root partition.
echo "Encrypting root partition..."
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/linux
cryptsetup luksOpen /dev/disk/by-partlabel/linux linux

# Create file systems
echo "Making File Systems..."
mkfs.fat -F32 -n EFISYSTEM /dev/disk/by-partlabel/EFISYSTEM
mkfs.btrfs -L linux /dev/mapper/linux

# mount the root, and create + mount the EFI directory
echo "Mounting File Systems..."
mount /dev/mapper/linux "$rootmnt"
mkdir -p "$rootmnt"/efi
mount -t vfat /dev/disk/by-partlabel/EFISYSTEM "$rootmnt"/efi

#Update pacman mirrors and then pacstrap base install
echo "Pacstrapping..."
reflector --country FR --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K $rootmnt "${pacstrappacs[@]}" 

echo "Setting up environment..."
#set up locale/env
#add our locale to locale.gen
sed -i -e "/^#"$locale"/s/^#//" "$rootmnt"/etc/locale.gen
#remove any existing config files that may have been pacstrapped, systemd-firstboot will then regenerate them
rm "$rootmnt"/etc/{machine-id,localtime,hostname,locale.conf,vconsole.conf} ||
systemd-firstboot --root "$rootmnt" \
	--keymap="$keymap" --locale="$locale" \
	--locale-messages="$locale" --timezone="$timezone" \
	--hostname="$hostname" --setup-machine-id \
	--welcome=false
arch-chroot "$rootmnt" locale-gen
echo "Configuring for first boot..."
#add the local user
arch-chroot "$rootmnt" useradd -m "$username"
#create a basic kernel cmdline, we're using DPS so we don't need to have anything here really, but if the file doesn't exist, mkinitcpio will complain
echo "quiet rw" > "$rootmnt"/etc/kernel/cmdline
#change the HOOKS in mkinitcpio.conf to use systemd hooks for decryption at boot
sed -i \
    -e 's/base udev/base systemd/g' \
    -e 's/keymap consolefont/sd-vconsole sd-encrypt/g' \
    "$rootmnt"/etc/mkinitcpio.conf
#change the preset file to generate a Unified Kernel Image instead of an initram disk + kernel
sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    -e 's/fallback_config=/#fallback_config=/g' \
    -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" \
    "$rootmnt"/etc/mkinitcpio.d/linux-zen.preset

#read the UKI setting and create the folder structure otherwise mkinitcpio will crash
declare $(grep default_uki "$rootmnt"/etc/mkinitcpio.d/linux-zen.preset)
arch-chroot "$rootmnt" mkdir -p "$(dirname "${default_uki//\"}")"

#enable the services we will need on start up
echo "Enabling services..."
systemctl --root "$rootmnt" enable systemd-resolved systemd-timesyncd NetworkManager
#mask systemd-networkd as we will use NetworkManager instead
systemctl --root "$rootmnt" mask systemd-networkd
#regenerate the ramdisk, this will create our UKI
echo "Generating UKI and installing Boot Loader..."
arch-chroot "$rootmnt" mkinitcpio -P
echo "Setting up Secure Boot..."
if [[ "$(efivar -d --name 8be4df61-93ca-11d2-aa0d-00e098032b8c-SetupMode)" -eq 1 ]]; then
arch-chroot "$rootmnt" sbctl create-keys
arch-chroot "$rootmnt" sbctl enroll-keys -m
arch-chroot "$rootmnt" sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
arch-chroot "$rootmnt" sbctl sign -s "${default_uki//\"}"
arch-chroot "$rootmnt" sbctl status
arch-chroot "$rootmnt" sbctl verify
else
echo "Not in Secure Boot setup mode. Skipping..."
fi
#install the systemd-boot bootloader
arch-chroot "$rootmnt" bootctl install --esp-path=/efi
#lock the root account
#arch-chroot "$rootmnt" usermod -L root
#and we're done


echo "-----------------------------------"
echo "- Install complete. Please reboot.... -"
echo "-----------------------------------"
sync
#reboot


