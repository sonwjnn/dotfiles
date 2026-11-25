function oc-go
    set -lx OPENCODE_CONFIG_CONTENT (string collect < $HOME/.config/opencode/profiles/models-opencode-go.json)
    opencode $argv
end
