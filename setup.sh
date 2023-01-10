#!/bin/bash

ABS_PATH=$(readlink -f "$0")
ABS_DIR=$(dirname "$ABS_PATH")
DOTFILES_PATH="$HOME/dev/dotfiles"

log() {
  echo -e "\033[0;32m[+] $1\033[0m"
}

error_log() {
  echo -e "\033[0;31m[-] $1\033[0m"
}

warning_log() {
  echo -e "\033[1;33m[-] $1\033[0m"

}

install_package() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "installing $1"
    if which apt >/dev/null 2>&1; then
      sudo http_proxy=$http_proxy https_proxy=$https_proxy apt install -y $1
    else
      error_log "not working on a debian based system, better do setup manually"
      exit 1
    fi
  else
    warning_log "$1 already installed"
  fi
}

usage() {
  # Print usage message
  cat << EOF
Usage $0 [options]

OPTIONS:
    -h Show this message
    -a Do everything
    -c Clone configuration files
    -z Install and setup ZSH shell
    -t Install and setup tmux
    -v Install and setup vim editor
    -u Setup automatic updates for dotfiles
    -s Install misc. software

EOF
}

setup_dotfiles() {
  # setup dotfiles directory in ~/dev/ and copy SSH keys to ~/.ssh
  install_package git
  install_package gpg

  # SSH keys need decrypted
  log "decrypting SSH keys"
  gpg --no-symkey-cache "$ABS_DIR/keys.tgz.gpg"
  tar zxf "$ABS_DIR/keys.tgz" -C "$ABS_DIR"
  rm -f "$ABS_DIR/keys.tgz"

  # why isn't this a default directory
  log "setting up SSH"
  mkdir -p "$HOME/.ssh"

  # move keys and fix permissions
  mv -f "$ABS_DIR/id_ed25519_github" "$HOME/.ssh/id_ed25519_github"
  mv -f "$ABS_DIR/id_ed25519_github.pub" "$HOME/.ssh/id_ed25519_github.pub"
  chown -R "$(whoami):$(whoami)" "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  chmod 600 "$HOME/.ssh/id_ed25519_github"
  chmod 600 "$HOME/.ssh/id_ed25519_github.pub"

  # clone the dotfiles directory into ~/dev/dotfiles
  log "cloning dotfiles to $DOTFILES_PATH"
  mkdir -p "$HOME/dev"
  git clone git@github.com:alexanderdean111/dotfiles "$DOTFILES_PATH"
  cd "$DOTFILES_PATH"
  git config user.email "alexander.dean111@gmail.com"
  git config user.name "Alexander Dean"
}

backup_config_file() {
  log "backing up $1"
  if [ -L $1 ]; then
    warning_log "Symlink $1 already exists, removing it"
    rm $1
  fi

  if [ -f $1 ]; then
    warning_log "$1 already exists, moving it to $1.bak"
    mv $1 "$1.bak"
  fi

  if [ -d $1 ]; then
    warning_log "directory $1 already exists, moving it to $1.bak"
    mv $1 "$1.bak"
  fi
}

setup_cron_updates() {
  # create a crontab file to install that will pull updates
  # from git every 6 hours
  log "Setting up cron job to update dotfiles every 6 hours"
  echo "0 */6 * * *     cd $ABS_DIR && git pull > /dev/null 2>&1" > $ABS_DIR/crontab
  crontab $ABS_DIR/crontab
  rm $ABS_DIR/crontab
}

install_zsh() {
  # Install and configure ZSH. Can be used stand-alone.
  install_package zsh

  # link config
  backup_config_file $HOME/.zshrc
  log "Creating symlink: $HOME/.zshrc"
  ln -s "$DOTFILES_PATH/zshrc" "$HOME/.zshrc"

  # Grab general ZSH config via oh-my-zsh project
  # See https://github.com/robbyrussell/oh-my-zsh
  ret=$(git clone https://github.com/robbyrussell/oh-my-zsh.git \
    $HOME/.oh-my-zsh >/dev/null 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "oh-my-zsh config already exists"
  fi

  # Set ZSH as my default shell
  backup_config_file $HOME/.bash_profile
  log "Creating symlink: $HOME/.bash_profile"
  ln -s "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"

  # Launch zsh at the end of .bashrc
  echo -e "$(which zsh)" >> "$HOME/.bashrc"
}

install_tmux() {
  install_package tmux
  install_package xclip

  # link config
  backup_config_file $HOME/.tmux.conf
  log "Creating symlink: $HOME/.tmux.conf"
  ln -s "$DOTFILES_PATH/tmux.conf" "$HOME/.tmux.conf"
}

install_vim() {

  log "installing vim plugins"
  ret=$(git clone https://github.com/vim-syntastic/syntastic.git \
    $DOTFILES_PATH/vim/pack/vendor/start/syntastic 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "Syntastic already installed, skipping"
  fi

  ret=$(git clone https://github.com/nvie/vim-flake8.git \
    $DOTFILES_PATH/vim/pack/vendor/start/vim-flake8 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "vim-flake8 already installed, skipping"
  fi
  
  ret=$(git clone https://github.com/preservim/nerdtree.git \
    $DOTFILES_PATH/vim/pack/vendor/start/nerdtree 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "nerdtree already installed, skipping"
  fi

  # link vim modules config
  backup_config_file $HOME/.vim
  log "Creating symlink: $HOME/.vim"
  ln -s "$DOTFILES_PATH/vim" "$HOME/.vim"

  install_package vim

  # link config
  backup_config_file $HOME/.vimrc
  log "Creating symlink: $HOME/.vimrc"
  ln -s "$DOTFILES_PATH/vimrc" "$HOME/.vimrc"
}

misc_software() {
  install_package python3
  install_package python3-dev
  install_package python3-venv

  install_package curl
  
  install_package jq

  install_package xclip

  log "deleting stupid default directories"
  rmdir ~/Templates >/dev/null 2>&1
  rmdir ~/Music >/dev/null 2>&1
  rmdir ~/Public >/dev/null 2>&1
  rmdir ~/Videos >/dev/null 2>&1
}

# If executed with no options
if [ $# -eq 0 ]; then
  usage
  exit 1
fi


while getopts ":hacztvus" opt; do
  case "$opt" in
    h)
      # Help message
      usage
      exit 1
      ;;
    a)
      # Do everything
      setup_dotfiles
      misc_software
      install_zsh
      install_tmux
      install_vim
      setup_cron_updates
      ;;
    c)
      # Clone configuration files
      setup_dotfiles
      ;;
    z)
      # Install and setup ZSH shell
      install_zsh
      ;;
    t)
      # Install and setup tmux terminal multiplexer
      install_tmux
      ;;
    v)
      # Install and setup vim editor
      install_vim
      ;;
    u)
      # Setup cron updates
      setup_cron_updates
      ;;
    s)
      # Install misc. software
      misc_software
      ;;
    *)
      # All other flags fall through to here
      usage
      exit 1
  esac
done
