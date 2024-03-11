#! /bin/sh

# hyprctl keyword windowrule "workspace 8 silent,Caprine" && hyprctl dispatch exec "caprine"
hyprctl keyword windowrule "workspace 7 silent,discord" && hyprctl dispatch exec "discord"
hyprctl keyword windowrule "workspace 2 silent,kitty" && hyprctl dispatch exec "kitty"

sleep 15

hyprctl keyword windowrule "unset,discord"
# hyprctl keyword windowrule "unset,Caprine"
hyprctl keyword windowrule "unset,kitty"
#hyprctl reload
