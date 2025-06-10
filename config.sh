#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Environment mode (default to test for now)
ENVIRONMENT_MODE="test"

# Legacy aliases for backward compatibility
GLOBAL_FILE=""
LOCAL_FILE=""

# Environment-aware path functions
get_global_commands_path() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$SCRIPT_DIR/test-commands/global/global-commands.sh"
    else
        echo "$HOME/.shell-commands/global/global-commands.sh"
    fi
}

get_local_commands_path() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$SCRIPT_DIR/test-commands/local-commands.sh"
    else
        echo "$HOME/.shell-commands/local-commands.sh"
    fi
}

get_commands_dir() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$SCRIPT_DIR/test-commands"
    else
        echo "$HOME/.shell-commands"
    fi
}

get_global_dir() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$SCRIPT_DIR/test-commands/global"
    else
        echo "$HOME/.shell-commands/global"
    fi
}

get_help_file() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$SCRIPT_DIR/test-commands/commands-help.txt"
    else
        echo "$HOME/.shell-commands/commands-help.txt"
    fi
}

get_zshrc_path() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$SCRIPT_DIR/zshrc_test"
    else
        echo "$HOME/.zshrc"
    fi
}

# Function to set environment mode
set_environment_mode() {
    if [[ "$1" == "test" || "$1" == "production" ]]; then
        ENVIRONMENT_MODE="$1"
        echo "Environment mode set to: $ENVIRONMENT_MODE"
    else
        echo "Invalid environment mode. Use 'test' or 'production'"
        return 1
    fi
}