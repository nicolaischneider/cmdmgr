#!/bin/bash

# Source configuration and all library modules
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib/command-operations.sh"
source "$(dirname "$0")/lib/parsing.sh"
source "$(dirname "$0")/lib/import.sh"
source "$(dirname "$0")/lib/git-operations.sh"
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
    "update") update_cmdmgr ;;
    "delete") delete_command ;;
    "edit") edit_command_file "$2" ;;
    "import") import_commands ;;
    "where-global") where_global ;;
    "pull-global") pull_global ;;
    "push-global") push_global ;;
    *)
        printf "Usage: %s [command]\n\n" "$(basename "$0")"
        printf "Setup & Management:\n"
        printf "  \033[1minstall\033[0m      - Add source lines to .zshrc\n"
        printf "  \033[1muninstall\033[0m    - Remove all commands and configuration\n"
        printf "Command Operations:\n"
        printf "  \033[1mcreate\033[0m       - Create a new command\n"
        printf "  \033[1mlist\033[0m         - List all available commands\n"
        printf "  \033[1mdelete\033[0m       - Delete an existing command\n"
        printf "  \033[1medit\033[0m [editor] - Edit command files with specified editor (default: vim)\n"
        printf "  \033[1mimport\033[0m       - Import existing functions and aliases from zshrc\n\n"
        printf "Global Commands Directory:\n"
        printf "  \033[1mwhere-global\033[0m - Print path to global commands directory\n"
        printf "  \033[1mpull-global\033[0m  - Pull latest changes from git in global commands directory\n"
        printf "  \033[1mpush-global\033[0m  - Add, commit and push changes in global commands directory\n"
        ;;
esac