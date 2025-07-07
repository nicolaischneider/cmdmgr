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
        echo "Installing in PRODUCTION mode - modifying actual .zshrc and installing cmdmgr for current user"
        # Install cmdmgr for current user only
        _install_user_cmdmgr
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
            show_installation_tutorial
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
_install_user_cmdmgr() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local user_bin_dir="$HOME/.local/bin"
    local cmdmgr_script="$user_bin_dir/cmdmgr"
    local current_user="$(whoami)"
    
    echo "Installing cmdmgr for user: $current_user"
    
    # Create user bin directory if it doesn't exist
    mkdir -p "$user_bin_dir"
    
    # Create the cmdmgr wrapper script with error handling
    local wrapper_content="#!/bin/bash
# cmdmgr user-specific wrapper script
# Installed by user: $current_user
# Installation path: $script_dir/cmdmgr.sh

CMDMGR_SCRIPT=\"$script_dir/cmdmgr.sh\"

# Check if the script exists and is executable
if [ ! -f \"\$CMDMGR_SCRIPT\" ]; then
    echo \"Error: cmdmgr.sh not found at \$CMDMGR_SCRIPT\"
    echo \"This usually means the cmdmgr installation was moved or deleted.\"
    echo \"Please reinstall cmdmgr from the correct location.\"
    exit 1
fi

if [ ! -x \"\$CMDMGR_SCRIPT\" ]; then
    echo \"Error: \$CMDMGR_SCRIPT is not executable\"
    echo \"Try running: chmod +x \$CMDMGR_SCRIPT\"
    exit 1
fi

# Execute the original script with all arguments
exec \"\$CMDMGR_SCRIPT\" \"\$@\"
"
    
    # Write the wrapper script
    echo "$wrapper_content" > "$cmdmgr_script"
    chmod +x "$cmdmgr_script"
    
    # Check if ~/.local/bin is in PATH and add it if necessary
    _setup_user_path "$user_bin_dir"
    
    # Verify installation
    if [ -f "$cmdmgr_script" ] && [ -x "$cmdmgr_script" ]; then
        echo "✓ cmdmgr installed in user directory: $cmdmgr_script"
        echo "✓ Installation registered for user: $current_user"
        
        # Test the installation (only if PATH is set up correctly)
        if [[ ":$PATH:" == *":$user_bin_dir:"* ]]; then
            if command -v cmdmgr &>/dev/null; then
                echo "✓ cmdmgr is available in your PATH"
                echo "✓ You can now use 'cmdmgr <command>' from anywhere"
            else
                echo "⚠️  cmdmgr installed but not immediately available"
                echo "   Restart your terminal or run: source ~/.zshrc"
            fi
        else
            echo "⚠️  PATH will be updated after restarting your terminal"
        fi
    else
        echo "✗ Failed to install cmdmgr for user"
        return 1
    fi
}

# Function to ensure ~/.local/bin is in PATH
_setup_user_path() {
    local user_bin_dir="$1"
    local shell_config_file
    
    # Determine which shell config file to use
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config_file="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_config_file="$HOME/.bashrc"
    else
        shell_config_file="$HOME/.profile"
    fi
    
    # Check if ~/.local/bin is already in PATH
    if [[ ":$PATH:" != *":$user_bin_dir:"* ]]; then
        echo "Adding $user_bin_dir to PATH in $shell_config_file"
        
        # Add PATH export to shell config file
        local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
        local path_comment="# Add user-specific bin directory to PATH"
        
        # Check if the line already exists in the file
        if ! grep -q "$path_line" "$shell_config_file" 2>/dev/null; then
            echo "" >> "$shell_config_file"
            echo "$path_comment" >> "$shell_config_file"
            echo "$path_line" >> "$shell_config_file"
            echo "✓ Added $user_bin_dir to PATH in $shell_config_file"
        else
            echo "✓ PATH already configured in $shell_config_file"
        fi
        
        # Update PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        echo "✓ PATH updated for current session"
    else
        echo "✓ $user_bin_dir already in PATH"
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