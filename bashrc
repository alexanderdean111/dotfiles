# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

export TERM="xterm-256color"

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend
shopt -s checkwinsize

# Source system bash completion if present
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Prompt: roughly equivalent to oh-my-zsh "ys" theme
# # user@host: /path (git-branch) [HH:MM:SS]
# $
__parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return
  printf '(%s) ' "$branch"
}
PS1='\[\e[1;33m\]# \[\e[1;36m\]\u\[\e[0m\]@\[\e[1;32m\]\h\[\e[0m\]: \[\e[1;34m\]\w\[\e[0m\] \[\e[1;31m\]$(__parse_git_branch)\[\e[0m\][\t]\n\$ '

# Stupid proof destructive commands
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias grep="grep --color=always"

# Enable colored ls output
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || \
    eval "$(dircolors -b)"
fi
alias ls="ls --color=auto"
alias l="ls -lh --color=auto"

# strip bash color codes
alias strip_bash_colors="sed 's/\x1b\[[0-9;]*m//g'"

# system clipboard commands
alias xcopy="xclip -selection clipboard"
alias xpaste="xclip -out -selection clipboard"

# quick proxy on/off
alias proxyon="export http_proxy=http://127.0.0.1:8080;export https_proxy=http://127.0.0.1:8080"
alias proxyoff="unset http_proxy;unset https_proxy"

# common git aliases
alias gst="git status"
alias gco="git checkout"
alias gd="git diff"
alias gl="git pull"
alias gp="git push"
alias gc="git commit -v"
alias gb="git branch"

# terminate tmux sessions that aren't "base"
tmuxclean() {
  for x in $(tmux ls | cut -d" " -f1 | tr -d ":" | grep -v base); do
    tmux kill-session -t "$x"
  done
}

# tmux setup: only auto-attach when interactive and not already inside tmux
if [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
  mkdir -p ~/tmux_terminal_logs
  tmux attach -t base 2>/dev/null || tmux new -s base 2>/dev/null
fi

# if we have a $HOME/.localBashMods file defined, load it now
# use this file for random path additions and aliases/mods specific to current
# machine without polluting main bashrc file
if [ -f "$HOME/.localBashMods" ]; then
  source "$HOME/.localBashMods"
fi
