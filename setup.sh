#!/usr/bin/env bash

EX_OK=0
EX_ERR=1
EX_USAGE=64

ROOT_HOME="/root"
ABS_PATH=$(readlink -f "$0")
ABS_DIR=$(dirname "$ABS_PATH")

log()
{
  echo -e "\033[0;32m[+] $1\033[0m"
}

error_log()
{
  echo -e "\033[0;31m[-] $1\033[0m"
}

warning_log()
{
  echo -e "\033[1;33m[-] $1\033[0m"

}

install_package()
{
  log "installing $1"
  if which apt-get >/dev/null 2>&1; then
    sudo http_proxy=$http_proxy https_proxy=$https_proxy apt install -y $1
  elif which dnf >/dev/null 2>&1; then
    sudo http_proxy=$http_proxy https_proxy=$https_proxy dnf install -y $1
  elif which yum >/dev/null 2>&1; then
    sudo http_proxy=$http_proxy https_proxy=$https_proxy yum install -y $1
  elif which pacman >/dev/null 2>&1; then
    sudo http_proxy=$http_proxy https_proxy=$https_proxy pacman -S --noconfirm $1
  else
    error_log "package manager not found"
    exit 1
  fi
}

usage()
{
  # Print usage message
  cat << EOF
Usage $0 [options]

Setup a Linux system.

OPTIONS:
    -h Show this message
    -a Do everything except i3 setup
    -c Clone configuration files
    -z Install and setup ZSH shell
    -t Install and setup tmux
    -v Install and setup vim editor
    -u Setup automatic updates for dotfiles
    -s Install misc. software
    -3 Setup i3 config

EOF
}

ensure_sudo()
{
  user=$(id | cut -d'=' -f2 | cut -d\( -f1)
  if [ $user -ne 0 ]; then
    error_log "This option needs root authentication to install."
    exit 1
  fi
}

backup_config_file()
{
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

clone_dotfiles()
{
  # Install git
  if ! command -v git >/dev/null 2>&1; then
    install_package git
  fi

  # Clone dotfiles
  if [ ! -d "$ABS_DIR" ]; then
    log "cloning dotfiles to $ABS_DIR"
    git clone https://github.com/alexanderdean111/dotfiles.git $ABS_DIR
  fi
}

setup_cron_updates()
{
  # create a crontab file to install that will pull updates
  # from git every 6 hours
  log "Setting up cron job to update dotfiles every 6 hours"
  echo "0 */6 * * *     cd $ABS_DIR && git pull > /dev/null 2>&1" > $ABS_DIR/crontab
  crontab $ABS_DIR/crontab
  rm $ABS_DIR/crontab
}

install_zsh()
{
  # Install and configure ZSH. Can be used stand-alone.
  if ! command -v zsh >/dev/null 2>&1; then
    install_package zsh
  fi

  # link config
  clone_dotfiles
  backup_config_file $HOME/.zshrc
  log "Creating symlink: $HOME/.zshrc"
  ln -s "$ABS_DIR/zshrc" "$HOME/.zshrc"

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
  ln -s "$ABS_DIR/bash_profile" "$HOME/.bash_profile"
}

install_tmux()
{
  if ! command -v tmux >/dev/null 2>&1; then
    install_package tmux
  fi

  if ! command -v xclip >/dev/null 2>&1; then
    install_package xclip
  fi

  # link config
  clone_dotfiles
  backup_config_file $HOME/.tmux.conf
  log "Creating symlink: $HOME/.tmux.conf"
  ln -s "$ABS_DIR/tmux.conf" "$HOME/.tmux.conf"
}

install_vim()
{
  # install Pathogen
  log "installing Pathogen"

  ret=$(git clone https://github.com/tpope/vim-pathogen.git \
    $ABS_DIR/vim/vim-pathogen 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "Pathogen already installed, skipping"
  else
    mkdir -p "$ABS_DIR/vim/autoload"
    ln -s "$ABS_DIR/vim/vim-pathogen/autoload/pathogen.vim" \
      "$ABS_DIR/vim/autoload/pathogen.vim"
  fi

  log "installing plugins"
  ret=$(git clone https://github.com/vim-syntastic/syntastic.git \
    $ABS_DIR/vim/bundle/syntastic 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "Syntastic already installed, skipping"
  fi

  ret=$(git clone https://github.com/nvie/vim-flake8.git \
    $ABS_DIR/vim/bundle/vim-flake8 2>&1)
  if [[ $ret =~ "already exists" ]]; then
    warning_log "vim-flake8 already installed, skipping"
  fi

  # link vim modules config
  backup_config_file $HOME/.vim
  log "Creating symlink: $HOME/.vim"
  ln -s "$ABS_DIR/vim" "$HOME/.vim"

  if ! command -v vim >/dev/null 2>&1; then
    install_package vim-minimal
    install_package vim-X11
    install_package vim
    install_package vim-enhanced
  fi

  # link config
  clone_dotfiles
  backup_config_file $HOME/.vimrc
  log "Creating symlink: $HOME/.vimrc"
  ln -s "$ABS_DIR/vimrc" "$HOME/.vimrc"
}

install_git()
{
  clone_dotfiles
  backup_config_file $HOME/.gitconfig
  log "Creating symlink: $HOME/.gitconfig"
  ln -s $ABS_DIR/gitconfig $HOME/.gitconfig
}

install_i3()
{
  # Install i3 WM if it isn't already installed
  if ! command -v i3 >/dev/null 2>&1; then
    install_package i3
  fi

  # Install i3status, used by i3 WM, if it isn't already installed
  if ! command -v i3status >/dev/null 2>&1; then
    install_package i3status
  fi

  # Install feh, if it isn't already installed
  if ! command -v feh >/dev/null 2>&1; then
    install_package feh
  fi

  # Clone configs, including i3 and i3status configurations
  clone_dotfiles

  # Create required dir for i3 config, if it doesn't exist
  # otherwise, back it up
  if [ ! -d $HOME/.i3 ]
  then
    mkdir $HOME/.i3
  fi

  # link config
  backup_config_file $HOME/.i3/config
  log "Creating symlink: $HOME/.i3/config"
  ln -s "$ABS_DIR/i3_config" "$HOME/.i3/config"

  # link i3status config
  backup_config_file $HOME/.i3status.conf
  log "Creating symlink: $HOME/.i3status.conf"
  ln -s "$ABS_DIR/i3status.conf" "$HOME/.i3status.conf"
}

misc_software()
{
  log "installing python"
  install_package python3
  install_package python3-dev
  install_package python3-venv

  log "installing curl"
  install_package curl
  
  log "installing jq"
  install_package jq

  log "installing xclip"
  install_package xclip

  log "deleting stupid default directories"
  rmdir ~/Templates
  rmdir ~/Music
  rmdir ~/Public
  rmdir ~/Videos
}

# If executed with no options
if [ $# -eq 0 ]; then
  usage
  exit $EX_USAGE
fi

while getopts ":hacztvu3s" opt; do
  case "$opt" in
    h)
      # Help message
      usage
      exit $EX_OK
      ;;
    a)
      # Do everything except install i3
      clone_dotfiles
      misc_software
      setup_cron_updates
      install_zsh
      install_tmux
      install_vim
      ;;
    c)
      # Clone configuration files
      clone_dotfiles
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
    3)
      # Setup i3 config
      install_i3
      ;;
    s)
      # Install misc. software
      misc_software
      ;;
    *)
      # All other flags fall through to here
      usage
      exit $EX_USAGE
  esac
done
