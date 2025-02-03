#!/bin/bash

# Configuration
COMMANDS_DIR="$HOME/.shell-commands"
GLOBAL_DIR="$COMMANDS_DIR/global"
GLOBAL_FILE="$GLOBAL_DIR/global-commands.sh"
LOCAL_FILE="$COMMANDS_DIR/local-commands.sh"
HELP_FILE="$COMMANDS_DIR/commands-help.txt"

# Create directories
mkdir -p "$GLOBAL_DIR"
touch "$GLOBAL_FILE" "$LOCAL_FILE" "$HELP_FILE"
chmod +x "$GLOBAL_FILE" "$LOCAL_FILE"

create_command() {
    echo "What's the name?"
    read -r name

    echo "What does it do? (Description)"
    read -r description

    echo "Global or Local? ([G|L])"
    read -r scope
    scope=$(echo "$scope" | tr '[:lower:]' '[:upper:]')

    if [ "$scope" = "G" ]; then
        target_file="$GLOBAL_FILE"
    elif [ "$scope" = "L" ]; then
        target_file="$LOCAL_FILE"
    else
        echo "Invalid scope. Use G for global or L for local."
        return 1
    fi

    temp_file=$(mktemp)
    
    echo "function $name() {" > "$temp_file"
    echo "  # Your code here" >> "$temp_file"
    echo "}" >> "$temp_file"

    vim "$temp_file"

    if [ -s "$temp_file" ]; then
        echo "" >> "$target_file"
        cat "$temp_file" >> "$target_file"
        echo "$name - $description" >> "$HELP_FILE"
        sort -o "$HELP_FILE" "$HELP_FILE"
        source "$target_file"
        echo "Command '$name' added. Remember to source .zshrc."
    else
        echo "Command creation cancelled."
    fi

    rm "$temp_file"
}

list_commands() {
    echo "Available Commands:"
    echo "=================="
    cat "$HELP_FILE"
}

check_zshrc() {
    local zshrc="$HOME/.zshrc"
    local source_lines=(
        "# Source shell command manager files"
        '[ -f "$HOME/.shell-commands/global/global-commands.sh" ] && source "$HOME/.shell-commands/global/global-commands.sh"'
        '[ -f "$HOME/.shell-commands/local-commands.sh" ] && source "$HOME/.shell-commands/local-commands.sh"'
    )
    
    if ! grep -q "Source shell command manager files" "$zshrc"; then
        echo "" >> "$zshrc"
        printf "%s\n" "${source_lines[@]}" >> "$zshrc"
        source "$zshrc"
        echo "Added source lines to .zshrc and sourced it"
    fi
}

uninstall() {
    echo "Are you sure you want to uninstall? This will remove all commands. [y/N]"
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    if [ "$response" = "Y" ]; then
        # Remove source lines from .zshrc
        sed -i '/Source shell command manager files/d' "$HOME/.zshrc"
        sed -i '/shell-commands\/.*commands.sh/d' "$HOME/.zshrc"
        
        # Remove command directory
        rm -rf "$COMMANDS_DIR"
        echo "Uninstallation complete. Please restart your shell."
    else
        echo "Uninstallation cancelled."
    fi
}

#!/bin/bash

# Configuration
COMMANDS_DIR="$HOME/.shell-commands"
GLOBAL_DIR="$COMMANDS_DIR/global"
GLOBAL_FILE="$GLOBAL_DIR/global-commands.sh"
LOCAL_FILE="$COMMANDS_DIR/local-commands.sh"
HELP_FILE="$COMMANDS_DIR/commands-help.txt"

# Create directories
mkdir -p "$GLOBAL_DIR"
touch "$GLOBAL_FILE" "$LOCAL_FILE" "$HELP_FILE"
chmod +x "$GLOBAL_FILE" "$LOCAL_FILE"

create_command() {
    echo "What's the name?"
    read -r name

    echo "What does it do? (Description)"
    read -r description

    echo "Global or Local? ([G|L])"
    read -r scope
    scope=$(echo "$scope" | tr '[:lower:]' '[:upper:]')

    if [ "$scope" = "G" ]; then
        target_file="$GLOBAL_FILE"
    elif [ "$scope" = "L" ]; then
        target_file="$LOCAL_FILE"
    else
        echo "Invalid scope. Use G for global or L for local."
        return 1
    fi

    temp_file=$(mktemp)
    
    echo "function $name() {" > "$temp_file"
    echo "  # Your code here" >> "$temp_file"
    echo "}" >> "$temp_file"

    vim "$temp_file"

    if [ -s "$temp_file" ]; then
        echo "" >> "$target_file"
        cat "$temp_file" >> "$target_file"
        echo "$name - $description" >> "$HELP_FILE"
        sort -o "$HELP_FILE" "$HELP_FILE"
        source "$target_file"
        echo "Command '$name' added and sourced."
    else
        echo "Command creation cancelled."
    fi

    rm "$temp_file"
}

list_commands() {
    echo "Available Commands:"
    echo "=================="
    cat "$HELP_FILE"
}

check_zshrc() {
    local zshrc="$HOME/.zshrc"
    local source_lines=(
        "# Source shell command manager files"
        '[ -f "$HOME/.shell-commands/global/global-commands.sh" ] && source "$HOME/.shell-commands/global/global-commands.sh"'
        '[ -f "$HOME/.shell-commands/local-commands.sh" ] && source "$HOME/.shell-commands/local-commands.sh"'
    )
    
    if ! grep -q "Source shell command manager files" "$zshrc"; then
        echo "" >> "$zshrc"
        printf "%s\n" "${source_lines[@]}" >> "$zshrc"
        source "$zshrc"
        echo "Added source lines to .zshrc and sourced it"
    fi
}

uninstall() {
    echo "Are you sure you want to uninstall? This will remove all commands. [y/N]"
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    if [ "$response" = "Y" ]; then
        # Remove source lines from .zshrc
        sed -i '/Source shell command manager files/d' "$HOME/.zshrc"
        sed -i '/shell-commands\/.*commands.sh/d' "$HOME/.zshrc"
        
        # Remove command directory
        rm -rf "$COMMANDS_DIR"
        echo "Uninstallation complete. Please restart your shell."
    else
        echo "Uninstallation cancelled."
    fi
}

delete_command() {
    echo "Enter command name to delete:"
    read -r name
    
    echo "Are you sure you want to delete '$name'? [y/N]"
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    if [ "$response" = "Y" ]; then
        # Delete from command files
        for target_file in "$GLOBAL_FILE" "$LOCAL_FILE"; do
            temp_file=$(mktemp)
            awk -v name="$name" '
              /^function[[:space:]]*'$name'[[:space:]]*\(\)[[:space:]]*{/,/^}/ {next}
              {print}
            ' "$target_file" > "$temp_file" && mv "$temp_file" "$target_file"
        done
        
        # Delete from help file
        temp_file=$(mktemp)
        sed "/^$name -/d" "$HELP_FILE" > "$temp_file" && mv "$temp_file" "$HELP_FILE"
        
        source "$GLOBAL_FILE" 2>/dev/null
        source "$LOCAL_FILE" 2>/dev/null
        echo "Command '$name' deleted"
    else
        echo "Deletion cancelled"
    fi
}

case "$1" in
    "create") create_command ;;
    "list") list_commands ;;
    "install") check_zshrc ;;
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