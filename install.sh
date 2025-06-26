#!/bin/bash

# INSTALL FUNCTION EXPLANATION:
# =============================
# This script handles the installation of cmdmgr in two phases:
#
# PHASE 1: Shell Integration Setup
# - Creates ~/.shell-commands/ directory structure for storing user commands
# - Adds sourcing lines to .zshrc so commands are available in new shell sessions
# - Creates empty global-commands.sh and local-commands.sh files if they don't exist
#
# PHASE 2: Global Binary Installation (Production Mode Only)
# - Creates a wrapper script at /usr/local/bin/cmdmgr that calls the main cmdmgr.sh
# - This allows users to type 'cmdmgr' from anywhere in the terminal
# - Requires sudo permissions to write to /usr/local/bin/
# - Shows tutorial with available commands and import suggestion
#
# Test mode only does Phase 1 with test files in the project directory

# Source configuration
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

install() {
    # Parse command line arguments to check for --test flag
    for arg in "$@"; do
        if [[ "$arg" == "--test" ]]; then
            set_environment_mode "test"
            break
        fi
    done
    
    # Use environment-aware path functions
    local target_file="$(get_zshrc_path)"
    local global_path="$(get_global_commands_path)"
    local local_path="$(get_local_commands_path)"
    
    # Set marker comment based on environment
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        local marker_comment="Source shell command manager files (TEST VERSION)"
        echo "Installing in TEST mode - files will be created in project folder"
    else
        local marker_comment="Source shell command manager files"
        echo "Installing in PRODUCTION mode - modifying actual .zshrc and installing cmdmgr globally"
        
        # Install cmdmgr globally in production mode
        _install_global_cmdmgr
    fi
    
    # Ensure directories exist and create all command files
    mkdir -p "$(dirname "$global_path")"
    mkdir -p "$(dirname "$local_path")"
    
    # Create command files if they don't exist
    [ ! -f "$global_path" ] && touch "$global_path" && chmod +x "$global_path"
    [ ! -f "$local_path" ] && touch "$local_path" && chmod +x "$local_path"
    
    # Define the lines that will be added to the target file
    local source_lines=(
        "# $marker_comment"
        "[ -f \"$global_path\" ] && source \"$global_path\""
        "[ -f \"$local_path\" ] && source \"$local_path\""
    )
    
    # Check if the target file doesn't exist OR doesn't already contain our marker comment
    if ! [ -f "$target_file" ] || ! grep -q "$marker_comment" "$target_file"; then
        # Add a blank line for spacing
        echo "" >> "$target_file"
        
        # Write each line from the source_lines array to the target file
        printf "%s\n" "${source_lines[@]}" >> "$target_file"
        
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Added source lines to zshrc_test file in project folder."
        else
            echo "Added source lines to .zshrc."
            
            # Show success tutorial in production mode only
            _show_installation_tutorial
        fi
    else
        # The lines are already present, so don't add them again
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Source lines already present in zshrc_test."
        else
            echo "Source lines already present in .zshrc."
        fi
    fi
}

# Private function - only used internally within install.sh
_install_global_cmdmgr() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local install_dir="/usr/local/bin"
    local cmdmgr_script="$install_dir/cmdmgr"
    
    # Check if we have write permissions to /usr/local/bin
    if [ ! -w "$install_dir" ]; then
        echo "Installing cmdmgr globally requires sudo permissions..."
        sudo_required="true"
    else
        sudo_required="false"
    fi
    
    # Create the cmdmgr wrapper script
    local wrapper_content="#!/bin/bash
# cmdmgr global wrapper script
# This script calls the original cmdmgr.sh with all arguments

exec \"$script_dir/cmdmgr.sh\" \"\$@\"
"
    
    # Install the wrapper script
    if [[ "$sudo_required" == "true" ]]; then
        echo "$wrapper_content" | sudo tee "$cmdmgr_script" > /dev/null
        sudo chmod +x "$cmdmgr_script"
    else
        echo "$wrapper_content" > "$cmdmgr_script"
        chmod +x "$cmdmgr_script"
    fi
    
    if [ -f "$cmdmgr_script" ]; then
        echo "✓ cmdmgr installed globally at: $cmdmgr_script"
        echo "✓ You can now use 'cmdmgr <command>' from anywhere"
    else
        echo "✗ Failed to install cmdmgr globally"
        return 1
    fi
}

# Private function - only used internally within install.sh
_show_installation_tutorial() {
    echo ""
    echo "🎉 CONGRATULATIONS! cmdmgr has been successfully installed!"
    echo "=========================================================="
    echo ""
    echo "You can now use 'cmdmgr' from anywhere in your terminal."
    echo ""
    echo "📋 Available Commands:"
    echo "  cmdmgr create    - Create a new shell command (interactive)"
    echo "  cmdmgr list      - List all your available commands"
    echo "  cmdmgr import    - Import existing commands from your .zshrc file"
    echo "  cmdmgr delete    - Delete an existing command (interactive)"
    echo "  cmdmgr edit      - Edit command files with your preferred editor"
    echo "  cmdmgr where     - Show location of global commands directory"
    echo "  cmdmgr pull      - Pull latest changes from global commands git repo"
    echo "  cmdmgr push      - Push changes to global commands git repo"
    echo "  cmdmgr uninstall - Remove cmdmgr and all associated files"
    echo ""
    echo "🚀 Quick Start:"
    echo "  1. Import your existing .zshrc commands: 'cmdmgr import'"
    echo "  2. Create your first new command: 'cmdmgr create'"
    echo "  3. List all available commands: 'cmdmgr list'"
    echo ""
    echo "💡 Tip: Your commands are organized into Global and Local scopes."
    echo "   Global commands are shared across projects, Local are project-specific."
    echo ""
}

update_cmdmgr() {
    echo "This will update the cmdmgr installation with the latest code from this directory."
    echo "Are you sure you want to update cmdmgr? [y/N]"
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    if [ "$response" = "Y" ]; then
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Update not needed in test mode - you're already using the latest code."
            return 0
        fi
        
        # Check if cmdmgr is globally installed
        if [ ! -f "/usr/local/bin/cmdmgr" ]; then
            echo "cmdmgr is not globally installed. Run 'install' first."
            return 1
        fi
        
        echo "Updating cmdmgr global installation..."
        
        # Call _install_global_cmdmgr directly since we're in the same file
        _install_global_cmdmgr
        
        if [ $? -eq 0 ]; then
            echo "✓ cmdmgr update completed successfully!"
            echo "The global cmdmgr command now points to the latest code."
        else
            echo "✗ cmdmgr update failed"
            return 1
        fi
    else
        echo "Update cancelled."
    fi
}