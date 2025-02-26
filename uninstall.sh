#!/bin/bash

uninstall() {
    echo "Are you sure you want to uninstall? This will remove all commands. [y/N]"
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    if [ "$response" = "Y" ]; then
        # Remove source lines from .zshrc
        sed -i '/Source shell command manager files/d' "$HOME/.zshrc"
        sed -i '/shell-commands\/.*commands.sh/d' "$HOME/.zshrc"
        
        # Remove command directory
        rm -rf "$COMMANDS_DIR"
        echo "Uninstallation complete. Please restart your shell."
    else
        echo "Uninstallation cancelled."
    fi
}