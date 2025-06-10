#!/bin/bash

# Source configuration and functions
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/functions.sh"
source "$(dirname "$0")/install.sh"
source "$(dirname "$0")/uninstall.sh"

# Create directories using environment-aware paths
mkdir -p "$(get_global_dir)"
touch "$(get_global_commands_path)" "$(get_local_commands_path)"
chmod +x "$(get_global_commands_path)" "$(get_local_commands_path)"

case "$1" in
    "create") create_command ;;
    "list") list_commands ;;
    "install") install ;;
    "uninstall") uninstall ;;
    "delete") delete_command ;;
    "edit") edit_command_file "$2" ;;  # New edit command with optional editor as $2
    *)
        echo "Usage: $(basename "$0") [create|list|install|uninstall|delete|edit]"
        echo "  create    - Create a new command"
        echo "  list      - List all available commands"
        echo "  install   - Add source lines to .zshrc"
        echo "  uninstall - Remove all commands and configuration"
        echo "  delete    - Delete an existing command"
        echo "  edit [editor] - Edit command files with specified editor (default: vim)"
        ;;
esac