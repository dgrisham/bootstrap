#!/usr/bin/env bash

logfile='/tmp/root_log'
[[ -f $logfile ]] && rm -f $logfile
exec 2>> $logfile
set -ex

# time
ln -s /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc

# locale
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
touch /etc/locale.conf
localectl set-locale LANG=en_US.UTF-8

# make sure we're up to date
pacman -Syyuq --noconfirm

# git
pacman -S --noconfirm git

# user
# ----

user='grish'

# packages required for user setup
pacman -S --noconfirm zsh sudo

useradd -m -G wheel -s /bin/zsh "$user"
# give sudo privileges to wheel group if not already given
if ! grep -xq '%wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
    echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
fi
# temporarily give password-less sudo access to user to automate makepkg
echo "$user ALL=(ALL) NOPASSWD: ALL" | EDITOR='tee -a' visudo

# update before we do anything
pacman -Syyu --noconfirm
sudo -H -u "$user" ./1-env.sh
sudo -H -u "$user" ./2-user.sh bootstrap all

# remove password-less sudo privilege for user
sed -i "/$user ALL=(ALL) NOPASSWD: ALL/d" /etc/sudoers

# set temporary password for user
echo "$user:password" | chpasswd
