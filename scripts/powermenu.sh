#!/bin/bash

# Define the options
options="🔒 Lock\n📺 Sleep\n🚪 Logout\n🔄 Reboot\n🛑 Shutdown"

selected=$(echo -e "$options" | fuzzel -d --prompt="Power: " --lines=5 --width=20)

# Execute based on selection
case $selected in
"🔒 Lock")
  hyprlock
  ;;
"📺 Sleep")
  systemctl suspend
  ;;
"🚪 Logout")
  niri msg action quit
  ;;
"🔄 Reboot")
  systemctl reboot
  ;;
"🛑 Shutdown")
  systemctl poweroff
  ;;
esac
