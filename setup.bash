#!/bin/bash
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

### OS Specific Setup ###

# Archlinux
if [ "$ID" == "arch" ]; then
    echo "Detected Arch-based distribution"

    # Install bat & bash_completion
    pacman --noconfirm --noprogressbar --needed -S bat bash-completion

    # Sourcing bashrc
    echo -e "\nif [ -f ~/.bash_aliases ]; then\n    . ~/.bash_aliases\nfi" >> /home/$user/.bashrc

    # set umask to 077
    echo -e "\numask 077" >> /home/$user/.bashrc

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

# Debian
elif [ "$ID" == "debian" ]; then
    echo "Detected Debian-based distribution"
    # Install bat
    apt-get -qq -y install bat
    # Add user aliases for debian
    cat aliases/debian >> "/home/$user/.bash_aliases"
fi

### Bash Setup ###

# Custom PS1
cat prompt/user >> "/home/$user/.bashrc"
chown $user: /home/$user/.bashrc
cat prompt/root >> "/root/.bashrc"

# Custom Aliases
cat aliases/user >> "/home/$user/.bash_aliases"
chown $user: /home/$user/.bash_aliases
cat aliases/root >> "/root/.bashrc"