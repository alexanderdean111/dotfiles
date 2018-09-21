#!/bin/bash

# get primary monitor dimensions
mon_dims=$(xrandr | grep "*" | head -1 | awk '{print $1}')
mon_dim_width=$(echo $dims | cut -d"x" -f1)
mon_dim_height=$(echo $dims | cut -d"x" -f2)
echo "[+] Detected primary monitor dimesions as $mon_dims"

# fix file globbing
shopt -s nullglob

# get the picture dir
if [ -z $1 ]; then
  echo "[-] No path specified"
  picdir="."
else
  if [ -d $1 ]; then
    picdir="$1"
  else
    echo "[!] Error: specified path does not exist (\"$1\")"
    exit 1
  fi
fi
echo "[+] Search path set to \"$picdir\""

# search for images and convert to $mon_dims if not already that size
for f in $picdir/*
do
  if file $f | grep -q "image data"; then
    pic_dims=$(convert $f -print '%wx%h\n' /dev/null)
    if [ $pic_dims = $mon_dims ]; then
      echo "[-] Skipping $f, already $mon_dims"
    else
      echo "[+] Converting $f from $pic_dims to $mon_dims -> $f.scaled.png"
      convert -resize $mon_dims! $f $f.scaled.png
    fi
  fi
done
