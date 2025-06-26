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
    
    # Read entire file into an array (compatible with older bash)
    local lines=()
    local line_count=0
    while IFS= read -r line; do
        lines[line_count]="$line"
        ((line_count++))
    done < "$zshrc_file"
    
    # Parse and collect functions and aliases
    local import_entries=""
    local description=""
    local func_count=0
    local alias_count=0
    local i=0
        
    while [ $i -lt $line_count ]; do
        local line="${lines[$i]}"
        
        # Skip our own command manager source lines
        if [[ "$line" =~ "Source shell command manager files" ]] || [[ "$line" =~ "shell-commands" ]] || [[ "$line" =~ "test-commands" ]]; then
            ((i++))
            continue
        fi
        
        # Check if line is a comment that could be a description
        if [[ "$line" =~ ^[[:space:]]*#{1,}[[:space:]]*(.*)$ ]]; then
            description="${BASH_REMATCH[1]}"
            ((i++))
            continue
        fi
        
        # Check for alias definitions
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=\"(.*)\"$ ]] || [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=\'(.*)\'$ ]]; then
            alias_name="${BASH_REMATCH[1]}"
            alias_command="${BASH_REMATCH[2]}"
            echo "Found alias: $alias_name with \"$alias_command\""
            
            # Create function entry for alias
            if [[ -n "$description" ]]; then
                import_entries="${import_entries}# $description"$'\n'
            else
                import_entries="${import_entries}# $alias_command"$'\n'
            fi
            import_entries="${import_entries}function $alias_name() {"$'\n'
            import_entries="${import_entries}    $alias_command \"\$@\""$'\n'
            import_entries="${import_entries}}"$'\n\n'
            
            alias_count=$((alias_count + 1))
            description=""
            ((i++))
            continue
        fi
        
        # Check for function definitions - handle multiple styles
        local func_name=""
        local func_start_line=$i
        
        # Pattern 1: function name() { or function name () {
        if [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{? ]]; then
            func_name="${BASH_REMATCH[1]}"
        # Pattern 2: name() { or name () {
        elif [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{? ]]; then
            func_name="${BASH_REMATCH[1]}"
        fi
        
        if [[ -n "$func_name" ]]; then
            echo "Found function: $func_name"
            # Initialize function body with the declaration line
            local func_body="$line"
            local brace_count=0
            local j=$i
            
            # Check if opening brace is on the same line
            if [[ "$line" =~ \{ ]]; then
                brace_count=1
            fi
            
            # Move to next line
            ((j++))
            
            # If no opening brace yet, look for it on the next line
            if [ $brace_count -eq 0 ] && [ $j -lt $line_count ]; then
                local next_line="${lines[$j]}"
                func_body="${func_body}"$'\n'"${next_line}"
                if [[ "$next_line" =~ \{ ]]; then
                    brace_count=1
                    ((j++))
                fi
            fi
            
            # Extract function body until closing brace
            while [ $j -lt $line_count ] && [ $brace_count -gt 0 ]; do
                local func_line="${lines[$j]}"
                func_body="${func_body}"$'\n'"${func_line}"
                
                # Count braces more accurately
                # Count opening braces
                local open_braces=$(echo "$func_line" | grep -o '{' | wc -l | tr -d ' ')
                brace_count=$((brace_count + open_braces))
                
                # Count closing braces
                local close_braces=$(echo "$func_line" | grep -o '}' | wc -l | tr -d ' ')
                brace_count=$((brace_count - close_braces))
                
                ((j++))
            done
            
            # Add function with description
            if [[ -n "$description" ]]; then
                import_entries="${import_entries}# $description"$'\n'
            else
                import_entries="${import_entries}# $func_name function"$'\n'
            fi
            import_entries="${import_entries}${func_body}"$'\n\n'
            
            func_count=$((func_count + 1))
            description=""
            
            # Update index to continue after the function
            i=$j
            continue
        fi
        
        # Reset description if we encounter non-comment, non-function, non-alias content
        if [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            description=""
        fi
        
        ((i++))
    done
    
    # Show what will be imported
    echo ""
    echo "Found $func_count functions and $alias_count aliases to import to $scope_name commands:"
    echo "================================="
    
    if [[ -n "$import_entries" ]]; then
        echo ""
        echo "⚠️  IMPORTANT: After importing, you may want to manually remove or comment out"
        echo "   the original aliases and functions from your .zshrc file to avoid conflicts."
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
            
            # Comment out the imported items in the original zshrc file
            _comment_out_migrated_items "$zshrc_file" "$target_file"
            
            echo "> ✅ Successfully imported $func_count functions and $alias_count aliases to $scope_name commands."
            echo "--------------------------------"
            echo "> ⚠️  IMPORTANT: The original functions and aliases have been commented out in your"
            echo "> .zshrc file with clear markers indicating they were migrated."
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
    
    # Read entire file into an array (compatible with older bash)
    local lines=()
    local line_count=0
    while IFS= read -r line; do
        lines[line_count]="$line"
        ((line_count++))
    done < "$source_file"
    
    # Create a temporary file for the modified zshrc
    local temp_file=$(mktemp)
    local i=0
    
    while [ $i -lt $line_count ]; do
        local line="${lines[$i]}"
        
        # Skip our own command manager source lines (don't comment these out)
        if [[ "$line" =~ "Source shell command manager files" ]] || [[ "$line" =~ "shell-commands" ]] || [[ "$line" =~ "test-commands" ]]; then
            echo "$line" >> "$temp_file"
            ((i++))
            continue
        fi
        
        # Check for alias definitions
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)= ]]; then
            alias_name="${BASH_REMATCH[1]}"
            echo "# MIGRATED TO $target_file - [$current_date], CAN BE DELETED" >> "$temp_file"
            echo "# $line" >> "$temp_file"
            ((i++))
            continue
        fi
        
        # Check for function definitions
        local func_name=""
        if [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\) ]] || [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\) ]]; then
            # Extract function name
            if [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                func_name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\) ]]; then
                func_name="${BASH_REMATCH[1]}"
            fi
            
            if [[ -n "$func_name" ]]; then
                # Comment out the function
                echo "# MIGRATED TO $target_file - [$current_date], CAN BE DELETED" >> "$temp_file"
                echo "# $line" >> "$temp_file"
                
                local brace_count=0
                if [[ "$line" =~ \{ ]]; then
                    brace_count=1
                fi
                
                ((i++))
                
                # Look for opening brace if not found
                if [ $brace_count -eq 0 ] && [ $i -lt $line_count ]; then
                    line="${lines[$i]}"
                    echo "# $line" >> "$temp_file"
                    if [[ "$line" =~ \{ ]]; then
                        brace_count=1
                    fi
                    ((i++))
                fi
                
                # Comment out function body
                while [ $i -lt $line_count ] && [ $brace_count -gt 0 ]; do
                    line="${lines[$i]}"
                    echo "# $line" >> "$temp_file"
                    
                    # Count braces
                    local open_braces=$(echo "$line" | grep -o '{' | wc -l | tr -d ' ')
                    brace_count=$((brace_count + open_braces))
                    local close_braces=$(echo "$line" | grep -o '}' | wc -l | tr -d ' ')
                    brace_count=$((brace_count - close_braces))
                    
                    ((i++))
                done
                continue
            fi
        fi
        
        # Regular line, keep as-is
        echo "$line" >> "$temp_file"
        ((i++))
    done
    
    # Replace the original file with the modified version
    mv "$temp_file" "$source_file"
    
    echo "Commented out migrated items in $source_file with clear markers."
}