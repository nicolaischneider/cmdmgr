#!/bin/bash

create_command() {
    echo "What's the name of your command?"
    read -r name

    echo "What does it do? (Description)"
    read -r description

    echo "Global or Local? ([G|L])"
    read -r scope
    scope=$(echo "$scope" | tr '[:lower:]' '[:upper:]')

    if [ "$scope" = "G" ]; then
        target_file="$(get_global_commands_path)"
    elif [ "$scope" = "L" ]; then
        target_file="$(get_local_commands_path)"
    else
        echo "Invalid scope. Use G for global or L for local."
        return 1
    fi

    temp_file=$(mktemp)
    
    # Create the function template with description comment above it
    echo "# $description" > "$temp_file"
    echo "function $name() {" >> "$temp_file"
    echo "  # Your code here" >> "$temp_file"
    echo "}" >> "$temp_file"

    vim "$temp_file"

    if [ -s "$temp_file" ]; then
        # Add spacing and then the commented function to the target file
        echo "" >> "$target_file"
        cat "$temp_file" >> "$target_file"
        echo "$name - $description" >> "$(get_help_file)"
        help_file="$(get_help_file)"
        sort -o "$help_file" "$help_file"
        echo "Command '$name' added. Please source your .zshrc to use it."
    else
        echo "Command creation cancelled."
    fi

    rm "$temp_file"
}

list_commands() {    
    # Function to extract functions and descriptions from a file
    parse_functions() {
        local file="$1"
        local section_name="$2"
        
        if [ ! -f "$file" ]; then
            return
        fi
        
        # Check if file has any functions before proceeding
        if ! grep -q "^function " "$file"; then
            return
        fi
        
        # Collect all function entries first
        local function_entries=""
        local description=""
        local line_num=0
        
        while IFS= read -r line; do
            line_num=$((line_num + 1))
            
            # Check if line is a comment
            if [[ "$line" =~ ^#[[:space:]](.*)$ ]]; then
                description="${BASH_REMATCH[1]}"
            # Check if line is a function definition
            elif [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]]; then
                func_name="${BASH_REMATCH[1]}"
                if [[ -n "$description" ]]; then
                    function_entries="${function_entries}- $func_name: $description"$'\n'
                else
                    function_entries="${function_entries}- $func_name: (no description)"$'\n'
                fi
                description=""
            # Reset description if we encounter other content
            elif [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^# ]] && [[ ! "$line" =~ ^function ]]; then
                description=""
            fi
        done < "$file"
        
        # Only display section if we found functions
        if [[ -n "$function_entries" ]]; then
            echo ""
            echo "# $section_name"
            echo -n "$function_entries"
        fi
    }
    
    # Parse global commands
    parse_functions "$(get_global_commands_path)" "Global Commands"
    
    # Parse local commands  
    parse_functions "$(get_local_commands_path)" "Local Commands"
    
    echo ""
}

delete_command() {
    echo "Enter command name to delete:"
    read -r name
    
    echo "Are you sure you want to delete '$name'? [y/N]"
    read -r response
    response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
    
    if [ "$response" = "Y" ]; then
        # Delete from command files
        for target_file in "$(get_global_commands_path)" "$(get_local_commands_path)"; do
            temp_file=$(mktemp)
            awk -v name="$name" '
              /^function[[:space:]]*'$name'[[:space:]]*\(\)[[:space:]]*{/,/^}/ {next}
              {print}
            ' "$target_file" > "$temp_file" && mv "$temp_file" "$target_file"
        done
        
        # Delete from help file
        temp_file=$(mktemp)
        help_file="$(get_help_file)"
        sed "/^$name -/d" "$help_file" > "$temp_file" && mv "$temp_file" "$help_file"
        
        echo "Command '$name' deleted. Please source your .zshrc to apply changes."
    else
        echo "Deletion cancelled"
    fi
}

edit_command_file() {
    local editor="$1"
    if [ -z "$editor" ]; then
        editor="vim"  # Default to Vim if no editor is specified
    fi

    echo "Edit Global or Local commands? ([G|L])"
    read -r scope
    scope=$(echo "$scope" | tr '[:lower:]' '[:upper:]')  # Convert input to uppercase for consistency

    if [ "$scope" = "G" ]; then
        file="$(get_global_commands_path)"  # Global commands file
    elif [ "$scope" = "L" ]; then
        file="$(get_local_commands_path)"   # Local commands file
    else
        echo "Invalid choice. Please type 'G' for global or 'L' for local."
        return 1  # Exit the function with an error status
    fi

    # Ensure directory exists before editing
    mkdir -p "$(dirname "$file")"
    
    $editor "$file"  # Open the selected file with the specified editor
    echo "Editing done. Run 'source $(get_zshrc_path)' to apply any changes."
}