# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export TERM="xterm-256color"
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="powerlevel9k/powerlevel9k"
ZSH_THEME="ys"
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# User configuration

#export PATH=$HOME/bin:/usr/local/bin:$PATH
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# Stupid proof destructive commands¬
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias grep="grep --color=always"

alias l="ls -lh"

# strip bash color codes
alias strip_bash_colors="sed 's/\x1b\[[0-9;]*m//g'"

# copy to system clipboard
alias xcopy="xclip -selection clipboard"

## Automatically start up or attach to tmux session if it is installed
#TMUX_INSTALLED=$(which tmux)
#if [[ "$?" == "0" ]]; then
#  echo "tmux is installed"
#  if [ -n "$TMUX" ]; then
#    echo "already in tmux session"
#  else
#    echo "not in tmux session, trying to attach to 'scratch'"
#    ret=$(tmux a -t scratch)
#    if [[ "$?" != "0" ]]; then
#      echo "tmux session 'scratch' doesn't exist, creating and attaching"
#      tmux new -s scratch
#    fi
#  fi
#else
#  echo "tmux not installed"
#fi

# tmux setup
tmux attach -t base || tmux new -s base

## SSH Agent Setup
# map known SSH_AUTH_SOCK
echo "using home directory: \"$HOME\""
export SSH_AUTH_SOCK="$HOME/.ssh/.auth_socket"

# Check if ssh-agent PID exists
check_pid=$(ps aux | grep "ssh-agent -a $SSH_AUTH_SOCK"| awk '{print $2}' | grep $(cat $HOME/.ssh/.auth_pid))

if [ -z "$check_pid" ]; then
  echo "No ssh-agent running, starting one up..."
  # clear remnants
  rm -f $HOME/.ssh/.auth_socket >/dev/null
  rm -f $HOME/.ssh/.auth_pid >/dev/null
  unset SSH_AGENT_PID
  eval $(ssh-agent -a "$SSH_AUTH_SOCK")
  echo "$SSH_AGENT_PID" > $HOME/.ssh/.auth_pid
  ssh-add 2>/dev/null
else
  echo "ssh-agent already running"
fi

export SSH_AGENT_PID="$(cat $HOME/.ssh/.auth_pid)"

# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export PATH=$HOME/.toolbox/bin:$PATH
