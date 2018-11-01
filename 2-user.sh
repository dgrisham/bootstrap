#!/bin/zsh

#   -   python language server
#       -   black, flake8 (be sure to link config after install)
#   -   pipenv
#   -   any other pip stuff?
#   -   install wenv

alias pacadd='sudo pacman -S --noconfirm'
alias auradd='yaourt --noconfirm'
alias pacrem='sudo pacman -Rsn --noconfirm'
alias aurrem='yaourt -Rsn --noconfirm'

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
        python)
            bootstrap_python
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
            ;;
        all)
            sudo pacman -Syyu --noconfirm
            bootstrap_prezto
            bootstrap_bin
            bootstrap_git
            bootstrap_tmux
            bootstrap_yaourt
            bootstrap_python
            bootstrap_kak
            bootstrap_wenv
            ;;
        *)
            echo "Unrecognized bootstrap request: '$cmd'" >&2
            ;;
    esac
}

reset() {
    local cmd="$1"
    shift
    case "$cmd" in
        prezto)
            reset_prezto
            ;;
        bin)
            reset_bin
            ;;
        git)
            reset_git
            ;;
        tmux)
            reset_tmux
            ;;
        yaourt)
            reset_yaourt
            ;;
        python)
            reset_python
            ;;
        kak)
            reset_kak
            ;;
        kak_lsp)
            reset_kak_lsp
            ;;
        kak_addons)
            reset_kak_addons
            ;;
        wenv)
            reset_wenv
            ;;
        all)
            reset_prezto
            reset_bin
            reset_git
            reset_tmux
            reset_kak
            reset_python
            reset_yaourt
            reset_wenv
            ;;
        test)
            test
            ;;
        *)
            echo "Unrecognized bootstrap request: '$cmd'" >&2
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

reset_prezto() {
    rm -rf "${ZDOTDIR:-$HOME}/.zprezto"
}

bootstrap_bin() {
    # clone bin
    [[ -z "$BIN" ]] && { echo "BIN not set" >&2 ; return 1 }
    git clone https://github.com/dgrisham/bin "$BIN"
}

reset_bin() {
    rm -rf "$BIN"
}

bootstrap_git() {
    ln -srf "$DOTFILES/git/config" "$HOME/.gitconfig"
    pacadd diff-so-fancy
}

reset_git() {
    pacrem diff-so-fancy
}

bootstrap_tmux() {
    pacadd tmux
    if [[ -d "$DOTFILES" ]]; then
        ln -srf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
    fi
}

reset_tmux() {
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

reset_yaourt() {
    pacrem package-query
    pacrem yaourt
}

bootstrap_python() {
    pacadd python python-pip
}

reset_python() {
    pacrem python python-pip
}

bootstrap_kak() {
    # text editor
    echo 1 | auradd kakoune-git
    bootstrap_kak_lsp
    bootstrap_kak_addons
}

bootstrap_kak_lsp() {
    echo 1 | auradd kak-lsp-git
    pacadd bash-language-server
    pip install --user python-language-server black pyls-black
    pip install --user flake8
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

reset_kak() {
    reset_kak_lsp
    reset_kak_addons
    aurrem kakoune-git
}

reset_kak_lsp() {
    pacrem bash-language-server
    pip uninstall -y python-language-server black pyls-black
    pip uninstall -y flake8
    unlink "$HOME/.config/flake8"
    #aurrem kak-lsp-git
}

reset_kak_addons() {
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

reset_wenv() {
    unlink "$WENVS/wenv"
    unlink "$DOTFILES/zsh/completion/wenv.bash"
    rm -rf "$SRC/wenv"
}

cmd="$1"
shift
case "$cmd" in
    bootstrap)
        bootstrap $@
        ;;
    reset)
        reset $@
        ;;
esac
