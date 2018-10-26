#!/bin/zsh

exec 2>> user_log
set -ex

# make sure dotfiles exists (should've been created in main.sh)
[[ ! -d "$DOTFILES" ]] && exit 1

# symlink a bunch of stuff
ln -sf $DOTFILES/zsh $HOME/.zsh
ln -sf $DOTFILES/zsh/zshrc $HOME/.zshrc
ln -sf $DOTFILES/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTFILES/git/config $HOME/.gitconfig

# clone zprezto
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
# prezto init script
ln -f $DOTFILES/zsh/zprezto/init.sh $HOME/.zprezto
# prezto theme
ln -f $DOTFILES/zsh/zprezto/prompt_steeef_setup $HOME/.zprezto/modules/prompt/functions

# clone bin
git clone https://github.com/dgrisham/bin $BIN

# To install:
#   -   python language server
#       -   black, flake8 (be sure to link config after install)
#   -   pipenv
#   -   any other pip stuff?
#   -   install go-ipfs, iptb, go-bitswap
