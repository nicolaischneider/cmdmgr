#!/bin/bash

install() {
    local zshrc="$HOME/.zshrc"
    local source_lines=(
        "# Source shell command manager files"
        '[ -f "$HOME/.shell-commands/global/global-commands.sh" ] && source "$HOME/.shell-commands/global/global-commands.sh"'
        '[ -f "$HOME/.shell-commands/local-commands.sh" ] && source "$HOME/.shell-commands/local-commands.sh"'
    )
    
    if ! grep -q "Source shell command manager files" "$zshrc"; then
        echo "" >> "$zshrc"
        printf "%s\n" "${source_lines[@]}" >> "$zshrc"
        source "$zshrc"
        echo "Added source lines to .zshrc and sourced it."
    else
        echo "Source lines already present in .zshrc."
    fi
}