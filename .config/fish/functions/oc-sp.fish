function oc-sp
    cp $HOME/.config/opencode/profiles/superpowers.tui.json $HOME/.config/opencode/tui.json
    or return
    env OPENCODE_CONFIG=$HOME/.config/opencode/profiles/superpowers.json opencode $argv
end
