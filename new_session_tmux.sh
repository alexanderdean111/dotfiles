#!/bin/bash

SESSION="$1"

if [ -z $SESSION ]; then
  echo "usage $(basename $(realpath $0)) <session_name>"
  exit
fi

# new session
tmux new-session -d -s $SESSION
tmux rename-window -t $SESSION:1 vim

# split vertical
tmux split-window -t $SESSION:1 -v
tmux resize-pane -t $SESSION:1.0 -D 20

# split window horizontal
tmux split-window -t $SESSION:1.0 -h

# split right column into four rows
#tmux split-window -t $SESSION:1.2 -v
#tmux split-window -t $SESSION:1.2 -v
#tmux split-window -t $SESSION:1.3 -v

# resize left pane
tmux resize-pane -t $SESSION:1.0 -R 30

# select left pane
tmux select-pane -t $SESSION:1.0

# attach or switch depending on if we are in a session
if [ -z $TMUX ]; then
  tmux attach -t $SESSION
else
  tmux switch-client -t $SESSION
fi

