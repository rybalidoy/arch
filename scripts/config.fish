if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Starship prompt
starship init fish | source

# Add ~/.local/bin to PATH
set -gx PATH $HOME/.local/bin $PATH

# Keybinding: Ctrl+f opens tmux-sessionizer
function fish_user_key_bindings
    bind \cf tmux-sessionizer
end


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Aliases
source ~/.config/fish/alias.fish
