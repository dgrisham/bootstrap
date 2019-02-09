#!/bin/zsh

#   To add:
#   -   dependency controls (e.g. 'uninstall wenv' vs. 'uninstall wenv + its deps'

alias pacadd='sudo pacman -S --noconfirm'
alias auradd='yaourt --noconfirm'
alias pacrem='sudo pacman -Rsn --noconfirm'
alias aurrem='yaourt -Rsn --noconfirm'

# TODO: make these profile sources optional
source /etc/zsh/profile
source "$HOME/.zsh/profile"

logfile='/tmp/user_log'
[[ -z $logfile ]] && rm -f $logfile
exec 2>> $logfile

bootstrap() {
    # TODO: would be nice to run as 'bootstrap prezto bin git ...'
    local cmd="$1"
    shift
    case "$cmd" in
        prezto)
            bootstrap_prezto
            ;;
        bin)
            bootstrap_bin
            ;;
        git)
            bootstrap_git
            ;;
        tmux)
            bootstrap_tmux
            ;;
        yaourt)
            bootstrap_yaourt
            ;;
        go)
            bootstrap_go
            ;;
        python)
            bootstrap_python
            ;;
        rust)
            bootstrap_rust
            ;;
        kak)
            bootstrap_kak
            ;;
        kak_lsp)
            bootstrap_kak_lsp
            ;;
        kak_addons)
            bootstrap_kak_addons
            ;;
        wenv)
            bootstrap_wenv
            bootstrap_taskwarrior
            ;;
        all)
            sudo pacman -Syyu --noconfirm
            bootstrap_prezto
            bootstrap_bin
            bootstrap_git
            bootstrap_tmux
            bootstrap_yaourt
            bootstrap_python
            bootstrap_go
            bootstrap_kak
            bootstrap_wenv
            bootstrap_taskwarrior
            bootstrap_ipfs
            ;;
        *)
            echo "Unrecognized bootstrap request: '$cmd'" >&2
            ;;
    esac
}

revert() {
    local cmd="$1"
    shift
    case "$cmd" in
        prezto)
            revert_prezto
            ;;
        bin)
            revert_bin
            ;;
        git)
            revert_git
            ;;
        tmux)
            revert_tmux
            ;;
        yaourt)
            revert_yaourt
            ;;
        go)
            revert_go
            ;;
        python)
            revert_python
            ;;
        rust)
            revert_rust
            ;;
        kak)
            revert_kak
            ;;
        kak_lsp)
            revert_kak_lsp
            ;;
        kak_addons)
            revert_kak_addons
            ;;
        wenv)
            revert_wenv
            revert_taskwarrior
            ;;
        all)
            revert_prezto
            revert_bin
            revert_git
            revert_tmux
            revert_kak
            revert_python
            revert_go
            revert_yaourt
            revert_wenv
            revert_taskwarrior
            revert_ipfs
            ;;
        *)
            echo "Unrecognized revert request: '$cmd'" >&2
            ;;
    esac
}

bootstrap_prezto() {
    local prezto_dir="${ZDOTDIR:-$HOME}/.zprezto"
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$prezto_dir"

    [[ ! -d "$DOTFILES" ]] && { echo "DOTFILES not set" >&2 ; return 1 }
    cd "$HOME"
    local dotfiles="${DOTFILES#$HOME}"

    # prezto init script
    ln -f "$DOTFILES/zsh/zprezto/init.zsh" "$prezto_dir"
    # prezto theme
    ln -f "$DOTFILES/zsh/zprezto/prompt_steeef_setup" "$prezto_dir/modules/prompt/functions"
}

revert_prezto() {
    rm -rf "${ZDOTDIR:-$HOME}/.zprezto"
}

bootstrap_bin() {
    # clone bin
    [[ -z "$BIN" ]] && { echo "BIN not set" >&2 ; return 1 }
    git clone https://github.com/dgrisham/bin "$BIN"
}

revert_bin() {
    rm -rf "$BIN"
}

bootstrap_git() {
    ln -srf "$DOTFILES/git/config" "$HOME/.gitconfig"
    pacadd diff-so-fancy
}

revert_git() {
    pacrem diff-so-fancy
}

bootstrap_tmux() {
    pacadd tmux
    if [[ -d "$DOTFILES" ]]; then
        ln -srf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
    fi
}

revert_tmux() {
    pacrem tmux
    unlink "$HOME/.tmux.conf"
}

bootstrap_yaourt() {
    [[ -z "$SCRATCH" ]] && local SCRATCH="$HOME"
    [[ ! -d "$SCRATCH" ]] && mkdir "$SCRATCH"
    cd "$SCRATCH"
    for pkg in 'package-query' 'yaourt'; do
        git clone https://aur.archlinux.org/$pkg.git $pkg
        cd $pkg
        makepkg -si --noconfirm
        cd ..
        rm -rf $pkg
    done
}

revert_yaourt() {
    pacrem package-query
    pacrem yaourt
}

bootstrap_go() {
    pacadd go
}

revert_go() {
    pacrem go
    rm -rf $GOPATH
}

bootstrap_python() {
    pacadd python python-pip python-pipenv
    echo 1 | auradd pyenv
}

revert_python() {
    pacrem python python-pip python-pipenv
    aurrem pyenv
}

bootstrap_rust() {
    pacadd rustup
    rustup install nightly
    rustup default nightly
}

revert_rust() {
    pacrem rustup
}

bootstrap_kak() {
    echo 1 | auradd kakoune-git
    bootstrap_kak_lsp
    bootstrap_kak_addons
}

bootstrap_kak_lsp() {
    bootstrap_rust
    echo 1 | auradd kak-lsp-git
    pacadd bash-language-server
    pip install --user python-language-server black pyls-black flake8
    [[ ! -d "$HOME/.config" ]] && mkdir "$HOME/.config"
    [[ ! -f "$DOTFILES/flake8" ]] && { echo "$DOTFILES/flake8 does not exist" >&2 ; return 1 }
    ln -srf "$DOTFILES/flake8" "$HOME/.config/flake8"
}

bootstrap_kak_addons() {
    [[ -z "$SRC" ]] && { echo "SRC not set" >&2 ; return 1 }
    [[ ! -d "$DOTFILES" ]] && { echo "$DOTFILES does not exist" >&2 ; return 1 }
    [[ ! -d "$SRC" ]] && mkdir "$SRC"

    autoload="$DOTFILES/kak/autoload"
    [[ ! -d "$autoload" ]] && mkdir "$autoload"
    ln -s /usr/share/kak/autoload "$autoload/autoload"

    local kakfiles="$SRC/kakoune"

    git clone https://github.com/Delapouite/kakoune-buffers "$kakfiles/buffers"
    ln -srf "$kakfiles/buffers/buffers.kak" "$autoload/buffers.kak"

    git clone https://github.com/lenormf/kakoune-extra "$kakfiles/extra"
    for n in 'comnotes' 'grepmenu' 'lineindent'; do
        ln -srf "$kakfiles/extra/$n.kak" "$autoload/$n.kak"
    done
}

revert_kak() {
    revert_kak_lsp
    revert_kak_addons
    aurrem kakoune-git
}

revert_kak_lsp() {
    pacrem bash-language-server
    pip uninstall -y python-language-server black pyls-black
    pip uninstall -y flake8
    unlink "$HOME/.config/flake8"
    aurrem kak-lsp-git
    revert_rust
}

revert_kak_addons() {
    [[ -z "$SRC" ]] && { echo "SRC not set" >&2 ; return 1 }

    for n in 'buffers' 'comnotes' 'grepmenu' 'lineindent'; do
        unlink "$DOTFILES/kak/autoload/$n.kak"
    done

    local kakfiles="$SRC/kakoune"
    rm -rf "$kakfiles/buffers"
    rm -rf "$kakfiles/extra"
    if [ -z "$(ls -A $kakfiles)" ]; then
        rm -rf "$kakfiles"
    fi
    autoload="$DOTFILES/kak/autoload"
    if [ -z "$(find $autoload \! -name autoload)" ]; then
        unlink "$DOTFILES/kak/autoload/autoload"
        rm -rf "$DOTFILES/kak/autoload"
    fi
}

bootstrap_wenv() {
    [[ -z "$SRC" ]] && { echo "SRC not set" >&2 ; return 1 }
    [[ -z "$WENVS" ]] && { echo "WENVS not set" >&2 ; return 1 }
    [[ ! -d "$SRC" ]] && mkdir "$SRC"
    git clone https://github.com/dgrisham/wenv "$SRC/wenv"
    ln -srf "$SRC/wenv/wenv" "$WENVS"

    [[ ! -d "$DOTFILES" ]] && { echo "DOTFILES not set" >&2 ; return 1 }
    compdir="$DOTFILES/zsh/completion"
    [[ ! -d "$compdir" ]] && mkdir "$compdir"
    ln -srf "$SRC/wenv/completion.bash" "$compdir/wenv.bash"
}

revert_wenv() {
    unlink "$WENVS/wenv"
    unlink "$DOTFILES/zsh/completion/wenv.bash"
    rm -rf "$SRC/wenv"
}

bootstrap_taskwarrior() {
    # expect package gives `unbuffer` command
    pacadd task expect
}

revert_taskwarrior() {
    pacrem task expect
}

cmd="$1"
shift
case "$cmd" in
    bootstrap)
        bootstrap $@
        ;;
    revert)
        revert $@
        ;;
esac
