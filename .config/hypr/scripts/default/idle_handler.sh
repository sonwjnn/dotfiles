#! /bin/bash

lockcmd="swaylock"

screenOff="sleep 5; hyprctl dispatch dpms off"
screenOn="hyprctl dispatch dpms on"

#lockcmd="swaylockd --screenshots --indicator --clock --inside-wrong-color f38ba8 --ring-wrong-color 11111b --inside-clear-color a6e3a1 --ring-clear-color 11111b --inside-ver-color 89b4fa --ring-ver-color 11111b --text-color  f5c2e7 --indicator-radius 80 --indicator-thickness 5 --effect-blur 10x7 --effect-vignette 0.2:0.2 --ring-color 11111b --key-hl-color f5c2e7 --line-color 313244 --inside-color 0011111b --separator-color 00000000 --fade-in 0.1"


sway-audio-idle-inhibit &
swayidle -w \
  timeout 900 "$lockcmd & $screenOff" \
    resume "$screenOn"


# original:
# bat=$(ls /sys/class/power_supply | grep -m 1 "BAT")

# sway-audio-idle-inhibit &
# swayidle -w \
#   timeout 1200 "$lockcmd & if [[ \"$(cat /sys/class/power_supply/$bat/status)\" == \"Discharging\" ]]; then systemctl suspend; else hyprctl dispatch dpms off; fi" resume "hyprctl dispatch dpms on"\
#     before-sleep "$lockcmd"
