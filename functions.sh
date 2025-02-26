#!/bin/bash

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
        echo "Command '$name' added. Please source your .zshrc to use it."
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
        
        echo "Command '$name' deleted. Please source your .zshrc to apply changes."
    else
        echo "Deletion cancelled"
    fi
}