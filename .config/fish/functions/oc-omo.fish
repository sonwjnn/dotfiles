function oc-omo
    cp $HOME/.config/opencode/profiles/omo.tui.json $HOME/.config/opencode/tui.json
    or return
    env OPENCODE_CONFIG=$HOME/.config/opencode/profiles/omo.json opencode $argv
end
