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
        
        # Remove the entire commands directory and all its contents
        # This includes global commands, local commands, and help files
        if [ -d "$commands_dir" ]; then
            rm -rf "$commands_dir"
            echo "Removed commands directory: $commands_dir"
        else
            echo "Commands directory not found: $commands_dir"
        fi
        
        # Handle zshrc cleanup - manual process for both test and production
        echo ""
        echo "=========================================="
        echo "IMPORTANT: Manual cleanup required!"
        echo "=========================================="
        
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Please manually remove these lines from your $target_zshrc file:"
            echo ""
            echo "# Source shell command manager files (TEST VERSION)"
            echo "[ -f \"$(get_global_commands_path)\" ] && source \"$(get_global_commands_path)\""
            echo "[ -f \"$(get_local_commands_path)\" ] && source \"$(get_local_commands_path)\""
        else
            echo "Please manually remove these lines from your ~/.zshrc file:"
            echo ""
            echo "# Source shell command manager files"
            echo "[ -f \"$(get_global_commands_path)\" ] && source \"$(get_global_commands_path)\""
            echo "[ -f \"$(get_local_commands_path)\" ] && source \"$(get_local_commands_path)\""
        fi
        
        echo ""
        echo "Would you like us to open the file for you to delete these lines? [y/N]"
        read -r edit_response
        edit_response=$(echo "$edit_response" | tr '[:lower:]' '[:upper:]')
        
        if [ "$edit_response" = "Y" ]; then
            # Open the file with the user's preferred editor (default to vim)
            ${EDITOR:-vim} "$target_zshrc"
            echo "File closed. Please restart your shell or run the appropriate source command when ready."
        else
            echo "Remember to manually remove the lines and restart your shell when ready."
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