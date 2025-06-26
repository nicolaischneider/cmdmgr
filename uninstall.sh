#!/bin/bash

# UNINSTALL FUNCTION EXPLANATION:
# ===============================
# This script handles the removal of cmdmgr installation in a safe, user-friendly way:
#
# WHAT IT REMOVES:
# - Global cmdmgr binary from /usr/local/bin/cmdmgr (production mode only)
# - Requires manual removal of sourcing lines from .zshrc (shows exact lines to delete)
#
# WHAT IT PRESERVES:
# - All user command files (~/.shell-commands/global/global-commands.sh)
# - All user command files (~/.shell-commands/local-commands.sh)
# - Shows exact file paths and command counts so users can manually import back to .zshrc
# - Does NOT delete any user-created commands or directories
#
# SAFETY FEATURES:
# - Requires explicit user confirmation before proceeding
# - Offers to open .zshrc file for manual editing
# - Provides clear instructions for cleanup steps
# - Shows preserved command files with their locations and command counts

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
        local global_commands_file="$(get_global_commands_path)"
        local local_commands_file="$(get_local_commands_path)"
        
        # Count existing commands in files before uninstalling
        local global_count=0
        local local_count=0
        
        if [ -f "$global_commands_file" ]; then
            global_count=$(grep -c "^function\|^[a-zA-Z_][a-zA-Z0-9_]*(" "$global_commands_file" 2>/dev/null || echo 0)
        fi
        
        if [ -f "$local_commands_file" ]; then
            local_count=$(grep -c "^function\|^[a-zA-Z_][a-zA-Z0-9_]*(" "$local_commands_file" 2>/dev/null || echo 0)
        fi
        
        # Remove global cmdmgr installation in production mode
        if [[ "$ENVIRONMENT_MODE" != "test" ]]; then
            uninstall_global_cmdmgr
        fi
        
        # Show preserved command files and their locations
        echo ""
        echo "🗂️  PRESERVED COMMAND FILES:"
        echo "============================================"
        echo ""
        
        if [ -f "$global_commands_file" ]; then
            echo "📁 Global Commands: $global_commands_file"
            echo "   └── Contains $global_count command(s)"
        else
            echo "📁 Global Commands: $global_commands_file (file not found)"
        fi
        
        if [ -f "$local_commands_file" ]; then
            echo "📁 Local Commands: $local_commands_file"
            echo "   └── Contains $local_count command(s)"
        else
            echo "📁 Local Commands: $local_commands_file (file not found)"
        fi
        
        echo ""
        echo "💡 These files contain your custom commands and have NOT been deleted."
        echo "   You can manually copy functions back to your .zshrc if needed."
        echo ""
        
        # Handle zshrc cleanup - manual process for both test and production
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

uninstall_global_cmdmgr() {
    local install_dir="/usr/local/bin"
    local cmdmgr_script="$install_dir/cmdmgr"
    
    if [ -f "$cmdmgr_script" ]; then
        # Check if we have write permissions to /usr/local/bin
        if [ ! -w "$install_dir" ]; then
            echo "Removing global cmdmgr requires sudo permissions..."
            sudo rm -f "$cmdmgr_script"
        else
            rm -f "$cmdmgr_script"
        fi
        
        if [ ! -f "$cmdmgr_script" ]; then
            echo "✓ Removed global cmdmgr installation from: $cmdmgr_script"
        else
            echo "✗ Failed to remove global cmdmgr installation"
        fi
    else
        echo "Global cmdmgr installation not found at: $cmdmgr_script"
    fi
}