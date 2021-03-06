# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export TERM="xterm-256color"

#ZSH_THEME="powerlevel9k/powerlevel9k"
ZSH_THEME="ys"
plugins=(git)

# User configuration

source $ZSH/oh-my-zsh.sh

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

#go back one git commit
alias gitback="git checkout $(git log -2 HEAD --pretty=format:%h | sed -n '2 p')"

# termiante tmux sessions that aren't "base"
tmuxclean() {
  for x in $(tmux ls | cut -d" " -f1 | tr -d ":" | grep -v base); do
    tmux kill-session -t $x
  done
}
# tmux setup
tmux attach -t base || tmux new -s base

# start tmux terminal logging
if [ ! -d ~/tmux_terminal_logs ]; then
  echo "no terminal logs directory, creating ~/tmux_terminal_logs"
  mkdir ~/tmux_terminal_logs
fi
tmux pipe-pane -o 'cat >>~/tmux_terminal_logs/tmux_output.#S:#W-#P'

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

export PATH=$HOME/.toolbox/bin:$PATH
