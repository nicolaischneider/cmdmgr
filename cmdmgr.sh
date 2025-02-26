#!/bin/bash

# Source configuration and functions
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/functions.sh"
source "$(dirname "$0")/install.sh"
source "$(dirname "$0")/uninstall.sh"

# Create directories
mkdir -p "$GLOBAL_DIR"
touch "$GLOBAL_FILE" "$LOCAL_FILE" "$HELP_FILE"
chmod +x "$GLOBAL_FILE" "$LOCAL_FILE"

case "$1" in
    "create") create_command ;;
    "list") list_commands ;;
    "install") install ;;
    "uninstall") uninstall ;;
    "delete") delete_command ;;
    *) 
        echo "Usage: $(basename "$0") [create|list|install|uninstall|delete]"
        echo "  create    - Create a new command"
        echo "  list      - List all available commands"
        echo "  install   - Add source lines to .zshrc"
        echo "  uninstall - Remove all commands and configuration"
        echo "  delete    - Delete an existing command"
        ;;
esac