#! /bin/bash
# Linux preferences setup
# Features :
#	- User and root prompt preferences
#	- User, root and os based aliases
#	- Debian and Archlinux specific setup
#
# Usage (as root): bash setup.bash
# Tested on Debian and Archlinux only


### Initialisation ###

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease run this script as root\e[0m"
    exit
fi

# Username prompt
read -p "$(echo -e "\e[34mEnter username: \e[m")" user

# OS Flavour
if [ -f /etc/os-release ]; then
    source /etc/os-release
fi


### Bash Setup ###

# Custom PS1
cat prompt/user >> "/home/$user/.bashrc"
cat prompt/root >> "/root/.bashrc"

# Motd
cat prompt/motd >> "/home/$user/.bashrc"
cat prompt/motd >> "/root/.bashrc"

# Custom Aliases
cat aliases/user >> "/home/$user/.bash_aliases"
cat aliases/root >> "/root/.bashrc"


### OS Specific Setup ###

# Archlinux
if [ "$ID" == "arch" ]; then

    # Aliases
    cat aliases/arch >> "/home/$user/.bash_aliases"

    # Pacman setup
    # Backup
    cp /etc/pacman.conf /etc/pacman.conf.bak

    # Configuration
    sed -i 's/^#Color$/Color/' /etc/pacman.conf
    sed -i 's/^#VerbosePkgLists$/VerbosePkgLists/' /etc/pacman.conf
    sed -i 's/^#ParallelDownloads.*$/ParallelDownloads = 5/' /etc/pacman.conf
    sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/' /etc/makepkg.conf

    # Figlet installation
    pacman -Sy figlet vim --needed --noconfirm


### Debian Specific Setup ###

# Debian
elif [ "$ID" == "debian" ]; then

    # Add user aliases for debian
    cat aliases/debian >> "/home/$user/.bash_aliases"

    # Figlet installation 
    apt update && apt install -y figlet

fi
