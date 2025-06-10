#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Production paths (original paths for actual use)
COMMANDS_DIR="$HOME/.shell-commands"
GLOBAL_DIR="$COMMANDS_DIR/global"
GLOBAL_COMMANDS_PATH="$GLOBAL_DIR/global-commands.sh"
LOCAL_COMMANDS_PATH="$COMMANDS_DIR/local-commands.sh"
HELP_FILE="$COMMANDS_DIR/commands-help.txt"

# Legacy aliases for backward compatibility
GLOBAL_FILE="$GLOBAL_COMMANDS_PATH"
LOCAL_FILE="$LOCAL_COMMANDS_PATH"

# Test paths (within the project folder for testing)
TEST_GLOBAL_COMMANDS_PATH="$SCRIPT_DIR/test-commands/global/global-commands.sh"
TEST_LOCAL_COMMANDS_PATH="$SCRIPT_DIR/test-commands/local-commands.sh"
TEST_ZSHRC_PATH="$SCRIPT_DIR/zshrc_test"
TEST_COMMANDS_DIR="$SCRIPT_DIR/test-commands"
TEST_GLOBAL_DIR="$TEST_COMMANDS_DIR/global"
TEST_HELP_FILE="$TEST_COMMANDS_DIR/commands-help.txt"

# Environment mode (default to test for now)
ENVIRONMENT_MODE="test"

# Environment-aware path functions
get_global_commands_path() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$TEST_GLOBAL_COMMANDS_PATH"
    else
        echo "$GLOBAL_COMMANDS_PATH"
    fi
}

get_local_commands_path() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$TEST_LOCAL_COMMANDS_PATH"
    else
        echo "$LOCAL_COMMANDS_PATH"
    fi
}

get_commands_dir() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$TEST_COMMANDS_DIR"
    else
        echo "$COMMANDS_DIR"
    fi
}

get_global_dir() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$TEST_GLOBAL_DIR"
    else
        echo "$GLOBAL_DIR"
    fi
}

get_help_file() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$TEST_HELP_FILE"
    else
        echo "$HELP_FILE"
    fi
}

get_zshrc_path() {
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        echo "$TEST_ZSHRC_PATH"
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