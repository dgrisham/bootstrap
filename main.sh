#!/usr/bin/env bash

exec 2>> main_log

user='grish'
alias paccmd='pacman -S --noconfirm'
basedir="$(dirname $(readlink -f $0))"

# make sure we're up to date
pacman -Syyuq --noconfirm

# git
paccmd -S git

# yaourt
cd /tmp
for pkg in 'package-query' 'yaourt'; do
    git clone https://aur.archlinux.org/$pkg.git
    cd $pkg
    makepkg -si
    cd ..
done
cd "$basedir"

# editor
yaourt --noconfirm kakoune-git
yaourt --noconfirm kak-lsp-git

# user
# ----

# packages required for user setup
paccmd zsh sudo

useradd -m -g "$user" -G wheel -s /bin/zsh "$user"
# give sudo privileges to wheel group if not already given
if ! grep -xq '%wheel ALL=(ALL) ALL' /etc/sudoers; then
    echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
fi

# rest of the packages we want
paccmd tmux docker python python-pip go diff-so-fancy

# set up user's dotfiles
userhome=$(eval echo "~$user")

# clone dotfiles
git clone https://github.com/dgrisham/dotfiles "$userhome/dotfiles"

# copy global etc files from repo before switching users
dotfiles="$userhome/dotfiles"
for file in $(find "$dotfiles/etc" -type f); do
    cp "$file" "${file#$dotfiles}"
done
chown -R grish:grish "$dotfiles"

# run the user setup script
chmod +x ./user.sh
sudo -H -u grish ./user.sh
