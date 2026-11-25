function oc2-openai
    set -lx OPENCODE_CONFIG_CONTENT (string collect < $HOME/.config/opencode/profiles/models-openai.json)
    opencode2 $argv --standalone
end
