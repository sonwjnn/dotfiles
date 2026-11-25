function oc-mixed
    set -lx OPENCODE_CONFIG_CONTENT (string collect < $HOME/.config/opencode/profiles/models-mixed.json)
    opencode $argv
end
