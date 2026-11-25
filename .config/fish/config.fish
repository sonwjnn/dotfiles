# brew
set -x POKEMON_ICAT_DATA $HOME/.local/share/pokemon-icat
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv fish)
end

# nvm (default node; switch: nvm use <ver> needs nvm.fish)
set -gx NVM_DIR $HOME/.nvm
if test -d $NVM_DIR/versions/node
    set -l default_node (ls -1 $NVM_DIR/versions/node | tail -1)
    if test -n "$default_node"
        fish_add_path $NVM_DIR/versions/node/$default_node/bin
    end
end

# PATH extras
# git worktree wrapper (herdr path sync) — must precede homebrew git
set -gx PATH $HOME/.local/bin $PATH

# pnpm
set -gx PNPM_HOME $HOME/Library/pnpm
fish_add_path $PNPM_HOME

# opencode
set -gx OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS true
set -gx VISION_MODE subagent
set -gx VISION_SUBAGENT_NAME observer

# atuin
set -gx ATUIN_TMUX_POPUP false

# starship
if type -q starship
    starship init fish | source
end

# fzf
if type -q fzf
    fzf --fish | source
end

# zoxide: z + cd. fish 4 embed fns → no share/.../cd.fish → manual wrap
if type -q zoxide
    function __zoxide_cd_internal
        builtin cd $argv
    end
    zoxide init fish | source
    alias cd z
end

# atuin
if type -q atuin
    atuin init fish | source
end

# aliases
alias ls 'lsd -la'
alias l 'lsd -l'
alias la 'lsd -a'
alias lla 'lsd -la'
alias lt 'lsd --tree'
alias vim nvim
alias cl clear
alias oc opencode
alias fs yazi

#interactive-only
if status is-interactive
    # fish built-in: syntax highlight, autosuggest, complete
    set -g fish_greeting
    # fix stale SHELL inherited from kitty launch env
    set -gx SHELL /opt/homebrew/bin/fish
    # herdr panes: use kitty TERM so viuer/fastfetch emit kitty graphics (herdr forwards them)
    if test "$HERDR_ENV" = "1"
        set -gx TERM kitty
    end

    function __pokemon_icat_clear_before_command --on-event fish_preexec
        if set -q __pokemon_icat_pending
            set -e __pokemon_icat_pending
            printf '\033_Ga=d,d=a,q=2\033\\'
        end
    end

    # viuer 0.7.1 chỉ nhận kitty graphics qua TERM, nên ép TERM riêng cho lệnh này
    function pokemon-icat
        if isatty stdout
            if test "$TERM_PROGRAM" = ghostty; or test "$TERM" = xterm-ghostty
                set -g __pokemon_icat_pending 1
            end
        end
        env TERM=xterm-kitty /opt/homebrew/bin/pokemon-icat $argv
    end

    # random pokemon on shell start
    if set -q POKEMON_ICAT_DATA; and test -d $POKEMON_ICAT_DATA
        pokemon-icat --height 14
    end
end

# Added by Antigravity CLI installer
fish_add_path $HOME/.local/bin

if type -q fnm
    fnm env --use-on-cd --shell fish | source
end

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/sonwin/Downloads/Compressed/google-cloud-sdk/path.fish.inc' ]; . '/Users/sonwin/Downloads/Compressed/google-cloud-sdk/path.fish.inc'; end
