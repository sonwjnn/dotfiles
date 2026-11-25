#!/bin/bash

config=$HOME/.config/hypr
scripts=$config/scripts


dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP & # for XDPH
dbus-update-activation-environment --systemd --all & # for XDPH

systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP & # for XDPH
/usr/lib/polkit-kde-authentication-agent-1 & # authentication dialogue for GUI apps
wl-paste --type text --watch cliphist store & # clipboard store text data
wl-paste --type image --watch cliphist store & # clipboard store image data

# screen locking when idle
$scripts/default/idle_handler.sh &
$scripts/autolaunch_on_workspace.sh &

fcitx5 & # input layout
libinput-gestures-setup start & # gestures for wayland
waybar & # launch the system panel
blueman-applet & # systray app for BT
nm-applet --indicator & # systray app for Network/Wifi
dunst & # start notification demon
