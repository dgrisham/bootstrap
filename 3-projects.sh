#!/bin/zsh

alias pacadd='sudo pacman -S --noconfirm'
alias auradd='yaourt --noconfirm'
alias pacrem='sudo pacman -Rsn --noconfirm'
alias aurrem='yaourt -Rsn --noconfirm'

# TODO: make these profile sources optional
source /etc/zsh/profile
source "$HOME/.zsh/profile"

logfile='/tmp/projects_log'
[[ -z $logfile ]] && rm -f $logfile
exec 2>> $logfile

bootstrap() {
    local cmd="$1"
    shift
    case "$cmd" in
        gx)
            bootstrap_gx
            ;;
        ipfs)
            bootstrap_gx
            bootstrap_ipfs
            ;;
        docker)
            bootstrap_docker
            ;;
        iptb)
            bootstrap_docker
            bootstrap_iptb
            ;;
        all)
            # would be cleaner if 'all' called bootstrap function (e.g. `bootstrap ipfs`
            # instead of `bootstrap_ipfs`). handles dependencies/ordering better
            bootstrap_gx
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
        gx)
            revert_gx
            ;;
        ipfs)
            revert_ipfs
            revert_gx
            ;;
        docker)
            revert_docker
            ;;
        iptb)
            revert_docker
            revert_iptb
            ;;
        all)
            revert_ipfs
            revert_gx
            ;;
        *)
            echo "Unrecognized revert request: '$cmd'" >&2
            ;;
    esac
}

bootstrap_iptb() {
    go get -u github.com/ipfs/iptb
    go get -d github.com/ipfs/iptb-plugins
    cd "$GOPATH/src/github.com/ipfs/iptb-plugins"
    make ipfsdocker install
    mkdir "$HOME/.iptb"
    ln -s "$GOPATH/src/github.com/ipfs/iptb-plugins/build" "$HOME/.iptb/plugins"
}

revert_iptb() {
    rm -f "$GOPATH/bin/iptb"
    rm -rf "$GOPATH/src/github.com/ipfs/iptb"
    rm -rf "$GOPATH/src/github.com/ipfs/iptb-plugins"
    rm -rf "$HOME/.iptb"
}

bootstrap_docker() {
    pacadd docker
}

revert_docker() {
    pacrem docker
}

bootstrap_ipfs() {
    go get -u -d github.com/ipfs/go-ipfs
    cd "$GOPATH/src/github.com/ipfs/go-ipfs"
    git remote add personal https://github.com/dgrisham/go-ipfs
    git fetch personal impl/bitswap/strategy-prq
    git checkout -t personal/impl/bitswap/strategy-prq

    gx-go lock-gen > gx-lock.json
    gx lock-install

    go get -u -d github.com/ipfs/go-bitswap
    cd "$GOPATH/src/github.com/ipfs/go-bitswap"
    git remote add personal https://github.com/dgrisham/go-bitswap
    git fetch personal impl/strategy-prq
    git checkout -t personal/impl/strategy-prq
    unlink "$GOPATH/src/github.com/ipfs/go-ipfs/vendor/github.com/ipfs/go-bitswap"
    cp -r "$GOPATH/src/github.com/ipfs/go-bitswap" "$GOPATH/src/github.com/ipfs/go-ipfs/vendor/github.com/ipfs"

    go get -u -d github.com/ipfs/go-ipfs-config
    cd "$GOPATH/src/github.com/ipfs/go-ipfs-config"
    git remote add personal https://github.com/dgrisham/go-ipfs-config
    git fetch personal experimental/bitswap-strategy-config
    git checkout -t personal/experimental/bitswap-strategy-config
    unlink "$GOPATH/src/github.com/ipfs/go-ipfs/vendor/github.com/ipfs/go-ipfs-config"
    cp -r "$GOPATH/src/github.com/ipfs/go-ipfs-config" "$GOPATH/src/github.com/ipfs/go-ipfs/vendor/github.com/ipfs"

    cd "$GOPATH/src/github.com/ipfs/go-ipfs"
    make install
    mkdir -p "$HOME/.ipfs"
    cp "misc/completion/ipfs-completion.bash" "$HOME/.ipfs/completion.bash"
}

revert_ipfs() {
    rm -f "$GOPATH/bin/ipfs"
    rm -rf "$GOPATH/src/github.com/ipfs/go-ipfs"
}

bootstrap_gx() {
    go get -u github.com/whyrusleeping/gx
    go get -u github.com/whyrusleeping/gx-go
}

revert_gx() {
    rm -f "$GOPATH/bin/gx{,-go}"
    rm -rf "$GOPATH/src/github.com/whyrusleeping/gx{,-go}"
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
