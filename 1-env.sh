#!/bin/zsh

logfile='/tmp/env_log'
[[ -f $logfile ]] && rm -f $logfile
exec 2>> $logfile
set -ex

cd "$HOME"
# would be nice to get dotfiles location from cloned zshrc, but chicken vs. egg
dotfiles="$HOME/dotfiles"
git clone https://github.com/dgrisham/dotfiles "$dotfiles"
branch='bakegood'
cd "$dotfiles"
git fetch origin "$branch"
git checkout "$branch"
cd "$HOME"

for file in $(find "$dotfiles/etc" -type f); do
    sudo cp "$file" "${file#$dotfiles}"
done
# reload systemctl and enable autoupdate daemon
sudo systemctl daemon-reload
sudo systemctl enable autoupdate

# source profile
source /etc/zsh/profile

[[ -z "$DOTFILES" ]] && { echo "DOTFILES env var not defined in /etc/zsh/profile" >&2 ; exit 1 }
ln -srf "$DOTFILES/zsh" "$HOME/.zsh"
ln -srf "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
