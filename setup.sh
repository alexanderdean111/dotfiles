#!/bin/bash

ABS_PATH=$(readlink -f "$0")
ABS_DIR=$(dirname "$ABS_PATH")
DOTFILES_PATH="$ABS_DIR"

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
    -b Install and setup bash shell
    -t Install and setup tmux
    -v Install and setup vim editor
    -u Setup automatic updates for dotfiles
    -s Install misc software

EOF
}

setup_dotfiles() {
  # setup dotfiles directory in ~/dev/ and copy SSH keys to ~/.ssh
  install_package git
  install_package gpg

  # SSH keys need decrypted
  log "decrypting SSH keys"
  gpg --no-symkey-cache "$ABS_DIR/keys.tgz.gpg"
  if [ ! -f "$ABS_DIR/keys.tgz" ]; then
    error_log "Failed to decrypt SSH keys, bad password"
    exit 1
  fi
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

  # make sure git is using SSH so we can push updates
  log "fixing git URL"
  cat "$ABS_DIR/.git/config" | sed -E 's/url = \S+/url = git@github.com:alexanderdean111\/dotfiles/' > "$ABS_DIR/.git/config.new"
  mv -f "$ABS_DIR/.git/config.new" "$ABS_DIR/.git/config"
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

install_bash() {
  # Install and configure bash. Can be used stand-alone.
  install_package bash

  # link bashrc
  backup_config_file $HOME/.bashrc
  log "Creating symlink: $HOME/.bashrc"
  ln -s "$DOTFILES_PATH/bashrc" "$HOME/.bashrc"

  # link bash_profile (sources ~/.bashrc on login shells)
  backup_config_file $HOME/.bash_profile
  log "Creating symlink: $HOME/.bash_profile"
  ln -s "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"
}

install_tmux() {
  install_package tmux
  install_package xclip

  # link config
  backup_config_file $HOME/.tmux.conf
  log "Creating symlink: $HOME/.tmux.conf"
  ln -s "$DOTFILES_PATH/tmux.conf" "$HOME/.tmux.conf"
}

install_or_update_vim_plugin() {
  # $1 = git URL, $2 = destination directory
  local url="$1"
  local dest="$2"
  local name
  name=$(basename "$dest")
  if [ -d "$dest/.git" ]; then
    log "updating vim plugin: $name"
    if ! git -C "$dest" pull --ff-only --quiet; then
      warning_log "failed to update $name"
    fi
  else
    log "installing vim plugin: $name"
    git clone --quiet "$url" "$dest"
  fi
}

remove_old_vim_plugin() {
  # $1 = destination directory of a plugin we no longer want
  local dest="$1"
  local name
  name=$(basename "$dest")
  if [ -d "$dest" ]; then
    warning_log "removing deprecated vim plugin: $name"
    rm -rf "$dest"
  fi
}

install_vim() {

  log "installing/updating vim plugins"
  mkdir -p "$DOTFILES_PATH/vim/pack/vendor/start"

  install_or_update_vim_plugin https://github.com/dense-analysis/ale.git \
    "$DOTFILES_PATH/vim/pack/vendor/start/ale"

  install_or_update_vim_plugin https://github.com/preservim/nerdtree.git \
    "$DOTFILES_PATH/vim/pack/vendor/start/nerdtree"

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
  # get latest python3 repo setup (deadsnakes PPA)
  install_package software-properties-common
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo http_proxy=$http_proxy https_proxy=$https_proxy apt update

  # latest stable Python (3.14 as of 2026)
  install_package python3.14
  install_package python3.14-dev
  install_package python3.14-venv

  install_package curl

  install_package jq

  install_package xclip
}

# If executed with no options
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

if [ "$(whoami)" == "root" ]; then
  error_log "Don't run as root, script will ask for sudo creds when it needs them"
fi

echo "ABS_PATH: $ABS_PATH"
echo "ABS_DIR: $ABS_DIR"

while getopts ":hacbtvus" opt; do
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
      install_bash
      install_tmux
      install_vim
      setup_cron_updates
      ;;
    c)
      # Clone configuration files
      setup_dotfiles
      ;;
    b)
      # Install and setup bash shell
      install_bash
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
