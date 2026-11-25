function oc-openai
    set -lx OPENCODE_CONFIG_CONTENT (string collect < $HOME/.config/opencode/profiles/models-openai.json)
    opencode $argv
end
