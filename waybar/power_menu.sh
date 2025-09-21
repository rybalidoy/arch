#!/bin/bash

# Power Menu using rofi
chosen=$(echo -e "Shutdown\nReboot\nLogout" | rofi -dmenu -i -p "Power Menu" -config ~/dotfiles/rofi/config-power.rasi)

case "$chosen" in
  Shutdown)
    systemctl poweroff
    ;;
  Reboot)
    systemctl reboot
    ;;
  Suspend)
    systemctl suspend
    ;;
  Logout)
    # adjust for your WM if needed
    hyprctl dispatch exit || pkill Hyprland
    ;;
  *)
    exit 0
    ;;
esac
