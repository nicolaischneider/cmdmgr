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
        echo "Command '$name' added. Please source your .zshrc to use it."
    else
        echo "Command creation cancelled."
    fi

    rm "$temp_file"
}

# Reusable function to extract functions and descriptions from a file
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

import_commands() {
    local zshrc_file="$(get_zshrc_path)"
    
    if [ ! -f "$zshrc_file" ]; then
        echo "No zshrc file found at: $zshrc_file"
        return 1
    fi
    
    echo "Importing functions and aliases from: $zshrc_file"
    echo ""
    
    # Ask user where to import to
    echo "Import all functions and aliases to Global or Local commands? ([G|L])"
    read -r scope
    scope=$(echo "$scope" | tr '[:lower:]' '[:upper:]')
    
    if [ "$scope" = "G" ]; then
        target_file="$(get_global_commands_path)"
        scope_name="Global"
    elif [ "$scope" = "L" ]; then
        target_file="$(get_local_commands_path)"
        scope_name="Local"
    else
        echo "Invalid scope. Use G for global or L for local."
        return 1
    fi
    
    # Parse and collect functions and aliases
    local import_entries=""
    local description=""
    local line_num=0
    local func_count=0
    local alias_count=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # Skip our own command manager source lines
        if [[ "$line" =~ "Source shell command manager files" ]] || [[ "$line" =~ "shell-commands" ]] || [[ "$line" =~ "test-commands" ]]; then
            continue
        fi
        
        # Check if line is a comment that could be a description
        if [[ "$line" =~ ^#[[:space:]](.*)$ ]]; then
            description="${BASH_REMATCH[1]}"
        # Check for alias definitions
        elif [[ "$line" =~ ^alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=\"(.*)\"$ ]]; then
            alias_name="${BASH_REMATCH[1]}"
            alias_command="${BASH_REMATCH[2]}"
            
            # Create function entry for alias
            import_entries="${import_entries}# $alias_command"$'\n'
            import_entries="${import_entries}function $alias_name() {"$'\n'
            import_entries="${import_entries}  $alias_command"$'\n'
            import_entries="${import_entries}}"$'\n\n'
            
            alias_count=$((alias_count + 1))
            description=""
        # Check for function definitions (both styles)
        elif [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]] || [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]]; then
            # Extract function name from either format
            if [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
                func_name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
                func_name="${BASH_REMATCH[1]}"
            fi
            
            if [[ -n "$func_name" ]]; then
                # Extract function body until closing brace
                local func_body="$line"$'\n'
                local brace_count=1
                
                while IFS= read -r func_line && [ $brace_count -gt 0 ]; do
                    func_body="${func_body}${func_line}"$'\n'
                    
                    # Count braces to find function end
                    if [[ "$func_line" =~ \{ ]]; then
                        brace_count=$((brace_count + 1))
                    fi
                    if [[ "$func_line" =~ ^\} ]]; then
                        brace_count=$((brace_count - 1))
                    fi
                done
                
                # Add function with description
                if [[ -n "$description" ]]; then
                    import_entries="${import_entries}# $description"$'\n'
                else
                    import_entries="${import_entries}# no description provided"$'\n'
                fi
                import_entries="${import_entries}${func_body}"$'\n'
                
                func_count=$((func_count + 1))
                description=""
                func_name=""
            fi
        # Reset description if we encounter other content
        elif [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^# ]] && [[ ! "$line" =~ ^function ]] && [[ ! "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\(\) ]] && [[ ! "$line" =~ ^alias ]]; then
            description=""
        fi
    done < "$zshrc_file"
    
    # Show what will be imported
    echo "Found $func_count functions and $alias_count aliases to import to $scope_name commands:"
    echo "================================="
    
    if [[ -n "$import_entries" ]]; then
        # Create a temporary file to display the preview
        local temp_preview=$(mktemp)
        echo "$import_entries" > "$temp_preview"
        parse_functions_from_file "$temp_preview" "Functions and Aliases to Import"
        rm "$temp_preview"
        
        echo ""
        echo "⚠️  IMPORTANT: After importing, you should remove the original aliases and functions"
        echo "   from your zshrc file to avoid conflicts and duplicates."
        echo ""
        echo "Do you want to proceed with the import? [y/N]"
        read -r response
        response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
        
        if [ "$response" = "Y" ]; then
            # Ensure target directory exists
            mkdir -p "$(dirname "$target_file")"
            
            # Append imports to target file
            echo "" >> "$target_file"
            echo "# Imported from zshrc on $(date)" >> "$target_file"
            echo "$import_entries" >> "$target_file"
            
            # Comment out the original functions and aliases in zshrc
            comment_out_migrated_items "$zshrc_file" "$target_file"
            
            echo "> \033[1;32mSuccessfully imported\033[0m $func_count functions and $alias_count aliases to $scope_name commands."
            echo "--------------------------------"
            echo "> Original functions/aliases have been commented out in $zshrc_file with migration markers."
            echo "> Please source $(get_zshrc_path) to use the new commands."
        else
            echo "Import cancelled."
        fi
    else
        echo "No functions or aliases found to import."
    fi
}

# Function to comment out migrated functions and aliases in the original zshrc file
comment_out_migrated_items() {
    local source_file="$1"
    local target_file="$2"
    local target_file_name=$(basename "$target_file")
    local current_date=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create a temporary file for the modified zshrc
    local temp_file=$(mktemp)
    local in_function=false
    local function_name=""
    local brace_count=0
    
    while IFS= read -r line; do
        # Skip our own command manager source lines (don't comment these out)
        if [[ "$line" =~ "Source shell command manager files" ]] || [[ "$line" =~ "shell-commands" ]] || [[ "$line" =~ "test-commands" ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi
        
        # Check for alias definitions
        if [[ "$line" =~ ^alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)= ]]; then
            alias_name="${BASH_REMATCH[1]}"
            echo "# MIGRATED TO $target_file - [$current_date], CAN BE DELETED" >> "$temp_file"
            echo "# $line" >> "$temp_file"
        # Check for function definitions (both styles)
        elif [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]] || [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]]; then
            # Extract function name from either format
            if [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
                function_name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
                function_name="${BASH_REMATCH[1]}"
            fi
            
            # Start commenting out this function
            in_function=true
            brace_count=1
            echo "# MIGRATED TO $target_file - [$current_date], CAN BE DELETED" >> "$temp_file"
            echo "# $line" >> "$temp_file"
        elif [[ "$in_function" == true ]]; then
            # We're inside a function that's being commented out
            echo "# $line" >> "$temp_file"
            
            # Count braces to find function end
            if [[ "$line" =~ \{ ]]; then
                brace_count=$((brace_count + 1))
            fi
            if [[ "$line" =~ ^\} ]]; then
                brace_count=$((brace_count - 1))
                if [[ $brace_count -eq 0 ]]; then
                    in_function=false
                    function_name=""
                fi
            fi
        else
            # Regular line, keep as-is
            echo "$line" >> "$temp_file"
        fi
    done < "$source_file"
    
    # Replace the original file with the modified version
    mv "$temp_file" "$source_file"
    
    echo "Commented out migrated items in $source_file with clear markers."
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

where_global() {
    local global_dir="$(get_global_dir)"
    echo "The directory for global commands can be found here:"
    echo "  $global_dir"
    echo ""
    echo "To navigate there, run:"
    echo "  cd \"$global_dir\""
}

pull_global() {
    local global_dir="$(get_global_dir)"
    
    if [ ! -d "$global_dir" ]; then
        echo "Global commands directory does not exist: $global_dir"
        echo "Run './cmdmgr.sh install' first to create the directory structure."
        return 1
    fi
    
    if [ ! -d "$global_dir/.git" ]; then
        echo "Global commands directory is not a git repository: $global_dir"
        echo "Initialize git in the directory first with 'git init'"
        return 1
    fi
    
    echo "Pulling latest changes in global commands directory..."
    cd "$global_dir" && git pull
}

push_global() {
    local global_dir="$(get_global_dir)"
    
    if [ ! -d "$global_dir" ]; then
        echo "Global commands directory does not exist: $global_dir"
        echo "Run './cmdmgr.sh install' first to create the directory structure."
        return 1
    fi
    
    if [ ! -d "$global_dir/.git" ]; then
        echo "Global commands directory is not a git repository: $global_dir"
        echo "Initialize git in the directory first with 'git init'"
        return 1
    fi
    
    echo "Pushing changes in global commands directory..."
    cd "$global_dir" && git add . && git commit -m "updated global commands" && git push
}