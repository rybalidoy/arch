#!/bin/bash

STYLE_DIR="$HOME/dotfiles/waybar/styles"
TARGET="$HOME/dotfiles/waybar/style.css"

# Get list of styles
styles=("$STYLE_DIR"/*.css)

# If TARGET doesn't exist, link the first
if [ ! -e "$TARGET" ]; then
  ln -sf "${styles[0]}" "$TARGET"
else
  # Resolve current symlink to absolute path
  current=$(realpath "$TARGET")
  found=false
  for ((i=0; i<${#styles[@]}; i++)); do
    style_path=$(realpath "${styles[$i]}")
    if [ "$style_path" = "$current" ]; then
      next_index=$(( (i + 1) % ${#styles[@]} ))
      found=true
      break
    fi
  done

  # If current not in list, default to first
  if ! $found; then
    next_index=0
  fi

  # Switch symlink
  ln -sf "${styles[$next_index]}" "$TARGET"
fi

# Restart Waybar by calling start.sh
~/dotfiles/waybar/start.sh
