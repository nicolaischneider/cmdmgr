#!/bin/bash

# Command Parsing Module
# Contains functions for parsing and listing commands from files

# Public function - used by other modules for parsing command files
parse_functions_from_file() {
    local file="$1"
    local section_name="$2"
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    # Check if file has any functions before proceeding (both styles)
    if ! grep -q -E "^function |^[a-zA-Z_][a-zA-Z0-9_]*\(\)" "$file"; then
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
        # Check if line is a function definition (both styles)
        elif [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]] || [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]]; then
            # Extract function name from either format
            if [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
                func_name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
                func_name="${BASH_REMATCH[1]}"
            fi
            
            if [[ -n "$func_name" ]]; then
                if [[ -n "$description" ]]; then
                    function_entries="${function_entries}- $func_name: $description"$'\n'
                else
                    function_entries="${function_entries}- $func_name: (no description)"$'\n'
                fi
                description=""
                func_name=""
            fi
        # Reset description if we encounter other content
        elif [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^# ]] && [[ ! "$line" =~ ^function ]] && [[ ! "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\(\) ]]; then
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

list_commands() {    
    echo "Available Commands:"
    echo "=================="
    
    # Parse global commands
    parse_functions_from_file "$(get_global_commands_path)" "Global Commands"
    
    # Parse local commands  
    parse_functions_from_file "$(get_local_commands_path)" "Local Commands"
    
    echo ""
}