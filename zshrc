# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export TERM="xterm-256color"

ZSH_THEME="ys"
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# Stupid proof destructive commands¬
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias grep="grep --color=always"

alias l="ls -lh"

# strip bash color codes
alias strip_bash_colors="sed 's/\x1b\[[0-9;]*m//g'"

# system clipboard commands
alias xcopy="xclip -selection clipboard"
alias xpaste="xclip -out -selection clipboard"

# quick proxy on/off
alias proxyon="export http_proxy=http://127.0.0.1:8080;export https_proxy=http://127.0.0.1:8080"
alias proxyoff="unset http_proxy;unset https_proxy"

# termiante tmux sessions that aren't "base"
tmuxclean() {
  for x in $(tmux ls | cut -d" " -f1 | tr -d ":" | grep -v base); do
    tmux kill-session -t $x
  done
}

# command to start logging a tmux pane manually
logpane() {
  mkdir -p ~/tmux_terminal_logs
  tmux pipe-pane -o 'cat >> ~/tmux_terminal_logs/tmux_output.#S:#W-#P'
}

# tmux setup
tmux attach -t base 2> /dev/null || tmux new -s base 2> /dev/null
mkdir -p ~/tmux_terminal_logs
tmux pipe-pane -o 'cat >> ~/tmux_terminal_logs/tmux_output.#S:#W-#P'

# if we have a $HOME/.localZshMods file defined, load it now
# use this file for random path additions and aliases/mods specific to current
# machine without polluting main zshrc file
if [ -f "$HOME/.localZshMods" ]; then
  source "$HOME/.localZshMods"
fi
