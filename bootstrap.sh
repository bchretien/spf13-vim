#!/usr/bin/env bash
############################  SETUP PARAMETERS
app_name='spf13-vim'
git_uri='https://github.com/spf13/spf13-vim.git'
git_branch='3.0'
debug_mode='0'
fork_maintainer='0'
dotfiles="$HOME/dotfiles"

############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ]; then
    msg "\e[32m[✔]\e[0m ${1}${2}"
    fi
}

error() {
    msg "\e[31m[✘]\e[0m ${1}${2}"
    exit 1
}

debug() {
    if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ]; then
      msg "An error occured in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
    fi
}

program_exists() {
    local ret='0'
    type $1 >/dev/null 2>&1 || { local ret='1'; }

    # throw error on non-zero return value
    if [ ! "$ret" -eq '0' ]; then
    error "$2"
    fi
}

############################ SETUP FUNCTIONS
lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
    ret="$?"
    debug
}

do_backup() {
    if [ -e "$2" ] || [ -e "$3" ] || [ -e "$4" ]; then
        today=`date +%Y%m%d_%s`
        for i in "$2" "$3" "$4"; do
            [ -e "$i" ] && [ ! -L "$i" ] && mv "$i" "$i.$today";
        done
        ret="$?"
        success "$1"
        debug
   fi
}

upgrade_repo() {
      msg "trying to update $1"

      if [ "$1" = "$app_name" ]; then
          cd "$dotfiles/.$app_name-3" &&
          git pull origin "$git_branch"
      fi

      if [ "$1" = "vundle" ]; then
          cd "$dotfiles/.vim/bundle/vundle" &&
          git pull origin master
      fi

      ret="$?"
      success "$2"
      debug
}

clone_repo() {
    program_exists "git" "Sorry, we cannot continue without GIT, please install it first."
    endpath="$dotfiles/.$app_name-3"

    if [ ! -e "$endpath/.git" ]; then
        git clone --recursive -b "$git_branch" "$git_uri" "$endpath"
        ret="$?"
        success "$1"
        debug
    else
        upgrade_repo "$app_name"    "Successfully updated $app_name"
    fi
}

clone_vundle() {
    if [ ! -e "$dotfiles/.vim/bundle/vundle" ]; then
        git clone https://github.com/gmarik/vundle.git "$dotfiles/.vim/bundle/vundle"
    else
        upgrade_repo "vundle"   "Successfully updated vundle"
    fi
    ret="$?"
    success "$1"
    debug
}

create_symlinks() {
    endpath="$dotfiles/.$app_name-3"

    if [ ! -d "$endpath/.vim/bundle" ]; then
        mkdir -p "$endpath/.vim/bundle"
    fi

    lnif "$endpath/.vimrc"              "$dotfiles/.vimrc"
    lnif "$endpath/.vimrc.bundles"      "$dotfiles/.vimrc.bundles"
    lnif "$endpath/.vimrc.before"       "$dotfiles/.vimrc.before"
    lnif "$endpath/.vim"                "$dotfiles/.vim"

    # Useful for fork maintainers
    touch  "$dotfiles/.vimrc.local"

    if [ -e "$endpath/.vimrc.fork" ]; then
        ln -sf "$endpath/.vimrc.fork" "$dotfiles/.vimrc.fork"
    elif [ "$fork_maintainer" -eq '1' ]; then
        touch "$dotfiles/.vimrc.fork"
        touch "$dotfiles/.vimrc.bundles.fork"
        touch "$dotfiles/.vimrc.before.fork"
    fi

    if [ -e "$endpath/.vimrc.bundles.fork" ]; then
        ln -sf "$endpath/.vimrc.bundles.fork" "$dotfiles/.vimrc.bundles.fork"
    fi

    if [ -e "$endpath/.vimrc.before.fork" ]; then
        ln -sf "$endpath/.vimrc.before.fork" "$dotfiles/.vimrc.before.fork"
    fi

    ret="$?"
    success "$1"
    debug
}

setup_vundle() {
    system_shell="$SHELL"
    export SHELL='/bin/sh'
    vim -u "$dotfiles/.vimrc.bundles" +BundleInstall! +BundleClean +qall
    export SHELL="$system_shell"

    success "$1"
    debug
}

############################ MAIN()
program_exists "vim" "To install $app_name you first need to install Vim."

do_backup   "Your old vim stuff has a suffix now and looks like .vim.`date +%Y%m%d%S`" \
        "$dotfiles/.vim" \
        "$dotfiles/.vimrc" \
        "$dotfiles/.gvimrc"

clone_repo      "Successfully cloned $app_name"

create_symlinks "Setting up vim symlinks"

clone_vundle    "Successfully cloned vundle"

setup_vundle    "Now updating/installing plugins using Vundle"

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://vim.spf13.com/"
