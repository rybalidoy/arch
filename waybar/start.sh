#!/bin/sh

killall waybar

# Wait until PipeWire is ready
for i in {1..10}; do
  if pactl info > /dev/null 2>&1; then
    break
  fi
  sleep 0.3
done

if [ "$USER" = "ryaai" ]; then
    waybar -c ~/dotfiles/waybar/config.jsonc -s ~/dotfiles/waybar/style.css &
else 
    waybar &
fi
