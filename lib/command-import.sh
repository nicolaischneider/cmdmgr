#!/bin/bash

# Command Import Module
# Contains functions for importing commands from .zshrc and managing migrations

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
            _comment_out_migrated_items "$zshrc_file" "$target_file"
            
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

# Private function - only used internally within command-import.sh
_comment_out_migrated_items() {
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