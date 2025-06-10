#!/bin/bash

uninstall() {
    # Get the current environment mode for appropriate messaging
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "Are you sure you want to uninstall? This will remove all TEST commands and files. [y/N]"
    else
        echo "Are you sure you want to uninstall? This will remove all PRODUCTION commands and files. [y/N]"
    fi
    
    # Read user confirmation and convert to uppercase for consistent comparison
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    # Only proceed if user explicitly confirms with 'Y'
    if [ "$response" = "Y" ]; then
        # Get environment-aware paths
        local target_zshrc="$(get_zshrc_path)"
        local commands_dir="$(get_commands_dir)"
        
        # Remove source lines from the appropriate zshrc file
        # This removes both the comment and the actual source lines
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            # For test mode, remove test-specific markers and source lines
            sed -i '/Source shell command manager files (TEST VERSION)/d' "$target_zshrc"
            sed -i '/test-commands\/.*commands.sh/d' "$target_zshrc"
            echo "Removed test source lines from zshrc_test file."
        else
            # For production mode, remove production markers and source lines
            sed -i '/Source shell command manager files/d' "$target_zshrc"
            sed -i '/shell-commands\/.*commands.sh/d' "$target_zshrc"
            echo "Removed production source lines from .zshrc file."
        fi
        
        # Remove the entire commands directory and all its contents
        # This includes global commands, local commands, and help files
        if [ -d "$commands_dir" ]; then
            rm -rf "$commands_dir"
            echo "Removed commands directory: $commands_dir"
        else
            echo "Commands directory not found: $commands_dir"
        fi
        
        # Provide environment-specific completion message
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Test environment uninstallation complete."
        else
            echo "Production uninstallation complete. Please restart your shell or run 'source ~/.zshrc'."
        fi
    else
        # User chose not to proceed with uninstallation
        echo "Uninstallation cancelled."
    fi
}