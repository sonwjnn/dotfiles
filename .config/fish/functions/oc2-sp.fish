function oc2-sp
    set -lx OPENCODE_CONFIG $HOME/.config/opencode/profiles/superpowers.json
    opencode2 $argv --standalone
end
