#!/bin/bash

if [ "$1" = "" ]; then
  echo -n "Enter directory name for test: "
  read dirname
else
  dirname="$1"
fi

if [ -d "$dirname" ]; then
  echo "directory exists, exiting"
  exit 1
fi

mkdir -p $dirname
ABS_DIR=$(readlink -f "$dirname")
echo "Setting up test directory: $ABS_DIR"
#sudo apt install python3
#sudo apt install python3-dev
#sudo apt install python3-venv

venv=$ABS_DIR/venv
python3 -m venv $venv

git clone https://github.com/drwetter/testssl.sh.git "$ABS_DIR/testssl"
git clone https://github.com/floyd-fuh/crass.git "$ABS_DIR/crass"

#$venv/bin/pip install --upgrade pip
#$venv/bin/pip install --upgrade setuptools
#$venv/bin/pip install --upgrade sslyze
#$venv/bin/pip install --upgrade scoutsuite

