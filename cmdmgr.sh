#!/bin/bash

# Configuration
COMMANDS_DIR="$HOME/.shell-commands"
GLOBAL_FILE="$COMMANDS_DIR/global-commands.sh"
LOCAL_FILE="$COMMANDS_DIR/local-commands.sh"
HELP_FILE="$COMMANDS_DIR/commands-help.txt"

# Create necessary directories and files if they don't exist
mkdir -p "$COMMANDS_DIR"
touch "$GLOBAL_FILE" "$LOCAL_FILE" "$HELP_FILE"

# Make sure the files are executable
chmod +x "$GLOBAL_FILE" "$LOCAL_FILE"

create_command() {
    echo "What's the name?"
    read -r name

    echo "What does it do? (Description)"
    read -r description

    echo "Global or Local? ([G|L])"
    read -r scope

    # Convert to uppercase for comparison
    scope=${scope^^}

    # Select the appropriate file based on scope
    if [ "$scope" = "G" ]; then
        target_file="$GLOBAL_FILE"
        echo "Creating global command..."
    elif [ "$scope" = "L" ]; then
        target_file="$LOCAL_FILE"
        echo "Creating local command..."
    else
        echo "Invalid scope. Please use G for global or L for local."
        return 1
    fi

    # Create a temporary file for the command
    temp_file=$(mktemp)
    
    # Add a comment header to the temp file
    echo "# Command: $name" > "$temp_file"
    echo "# Description: $description" >> "$temp_file"
    echo "" >> "$temp_file"

    # Open vim to edit the command
    vim "$temp_file"

    # If the temp file is not empty, append its contents to the target file
    if [ -s "$temp_file" ]; then
        echo "" >> "$target_file"  # Add a blank line for separation
        cat "$temp_file" >> "$target_file"
        echo "Command '$name' has been added."
        
        # Add to help file
        echo "$name - $description" >> "$HELP_FILE"
        sort -o "$HELP_FILE" "$HELP_FILE"  # Keep help file sorted alphabetically
    else
        echo "Command creation cancelled."
    fi

    # Clean up
    rm "$temp_file"
}

list_commands() {
    echo "Available Commands:"
    echo "=================="
    cat "$HELP_FILE"
}

# Check if we need to source these files in .zshrc
check_zshrc() {
    local zshrc="$HOME/.zshrc"
    local source_lines=(
        "# Source shell command manager files"
        '[ -f "$HOME/.shell-commands/global-commands.sh" ] && source "$HOME/.shell-commands/global-commands.sh"'
        '[ -f "$HOME/.shell-commands/local-commands.sh" ] && source "$HOME/.shell-commands/local-commands.sh"'
    )
    
    # Check if the lines already exist in .zshrc
    if ! grep -q "Source shell command manager files" "$zshrc"; then
        echo "" >> "$zshrc"
        printf "%s\n" "${source_lines[@]}" >> "$zshrc"
        echo "Added source lines to .zshrc"
        echo "Please run 'source ~/.zshrc' to apply changes"
    fi
}

# Main script logic
case "$1" in
    "create")
        create_command
        ;;
    "list")
        list_commands
        ;;
    "install")
        check_zshrc
        ;;
    *)
        echo "Usage: $(basename "$0") [create|list|install]"
        echo "  create  - Create a new command"
        echo "  list    - List all available commands"
        echo "  install - Add source lines to .zshrc"
        ;;
esac