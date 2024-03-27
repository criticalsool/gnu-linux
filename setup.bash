#! /bin/bash
# Linux preferences setup
# Features :
#	- User and root prompt preference
#	- User and root aliases
#	- Debian and Archlinux specific setup
#
# Usage : bash setup.bash

### Linux Setup ###

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

# .bash_profile
bash_profile=$(cat <<'EOL'
#
# ~/.bash_profile
#

# if running bash
if [ -n "$BASH_VERSION" ]
then
    # include .bashrc if it exists
    if [ -f "~/.bashrc" ]
    then
        . "~/.bashrc"
    fi
fi

EOL
)
echo "$bash_profile" > "/home/$user/.bash_profile"
echo "$bash_profile" > "/root/.bash_profile"


# .bashrc
bashrc=$(cat <<'EOL'
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Prompt
if [[ "$UID" -eq "0" ]]
then
    # Root Prompt
    PS1='(\[\e[33m\]\A\[\e[0m\]) \[\e[5m\]\[\e[31m\]\u\[\e(B\[\e[m\]\[\e[34m\]@\[\e[35m\]\h \[\e[34m\]\W \[\e[31m\]\$\[\e[0m\] '
else
    # User Prompt
    PS1='(\[\e[33m\]\A\[\e[0m\]) \[\e[32m\]\u\[\e[34m\]@\[\e[35m\]\h \[\e[34m\]\W \[\e[36m\]\$\[\e[0m\] '
fi

# Aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Motd
NONE="\e[m"
BOLD="\e[1m"
GREEN="\e[1;32m"
BLUE="\e[34m"
C_DARKRED="\e[38;5;88m"

printf $BOLD$C_DARKRED
figlet "    $USER"
printf $NONE

EOL
)
echo "$bashrc" > "/home/$user/.bashrc"
echo "$bashrc" > "/root/.bashrc"


# .bash_aliases
bash_aliases=$(cat <<'EOL'
#
# ~/.bash_aliases
#

### Aliases ###
alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias l="ls -lrth"
alias ll="l -a"

# Remove a directory and all files
alias rmd="rm  --recursive --force --verbose "

# Remove securely
alias shredd="shred -n 48 -uv "

# BTRFS
alias backup-list='sudo echo -e "${BLUE}" && sudo btrfs subv list / && echo -e "$NONE"'
alias backup="sudo btrfs subvolume snapshot / /.snapshots/root/$(date +%d-%m-%Y) && sudo btrfs subvolume snapshot /home /.snapshots/home/$(date +%d-%m-%Y)"
alias backup-delete='backup-list && read -p "$(echo -e "${GREEN}\nSaisir la date de la sauvegarde à supprimer (DD-MM-YYYY) : ${NONE}")" choix && sudo btrfs subvolume delete /.snapshots/root/${choix} && sudo btrfs subvolume delete /.snapshots/home/${choix}'

EOL
)
echo "$bash_aliases" > "/home/$user/.bash_aliases"
echo "$bash_aliases" > "/root/.bash_aliases"

# Specific User Aliases
bash_aliases=$(cat <<'EOL'

# IP alias
alias myip="wget https://myip.wtf/text -O - --quiet"

EOL
)
echo "$bash_aliases" >> "/home/$user/.bash_aliases"

# Specific Root Aliases
bash_aliases=$(cat <<'EOL'

# IP alias
alias myip="hostname -i"

# Root restricted editor aliases
alias nano="rnano"
alias vim="rvim"
alias vi="rvim"

EOL
)
echo "$bash_aliases" >> "/root/.bash_aliases"


### Arch Specific Setup ###

# If OS is Archlinux
if [ "$NAME" == "Arch Linux" ]; then

    # Add root bashrc stuff for arch : motd
    pacman -Sy figlet vim --needed --noconfirm
    bashrc=$(cat <<'EOL'
printf $BOLD
printf "   ${BLUE}pacman -Syyu    -   ${GREEN}System upgrade"
printf "\n"
printf "   ${BLUE}pacman -Qtd     -   ${GREEN}Check for orphans and dropped packages"
printf "\n"
printf "   ${BLUE}pacman -Ss      -   ${GREEN}Query the sync database"
printf "\n"
printf "   ${BLUE}pacman -Qs      -   ${GREEN}Search for already installed packages"
printf "\n"
printf "   ${BLUE}pacman -Rs      -   ${GREEN}Remove a package and its dependencies"
printf "\n"
printf $NONE
printf "\n"

EOL
)
    echo "$bashrc" >> "/root/.bashrc"


    # Pacman setup
    # Sauvegarde
    cp /etc/pacman.conf /etc/pacman.conf.bak

    # Configuration
    sed -i 's/^#Color$/Color/' /etc/pacman.conf
    sed -i 's/^#VerbosePkgLists$/VerbosePkgLists/' /etc/pacman.conf
    sed -i 's/^#ParallelDownloads.*$/ParallelDownloads = 5/' /etc/pacman.conf
    sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/' /etc/makepkg.conf


### Debian Specific Setup ###

# If OS is Debian
elif [ "$NAME" == "Debian" ]; then

    # Install figlet
    apt update && apt install -y figlet

    # Add user aliases for debian

    bash_aliases=$(cat <<'EOL'

# Update
alias update="sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"

EOL
)
    echo "$bash_aliases" >> "/home/$user/.bash_aliases"

    # Add root aliases for debian

    bash_aliases=$(cat <<'EOL'

# Update
alias update="apt update && apt full-upgrade -y && apt autoremove -y"

EOL
)
    echo "$bash_aliases" >> "/root/.bash_aliases"

fi
