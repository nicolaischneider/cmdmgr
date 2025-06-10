#!/bin/bash

# Source configuration
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

install() {
    # Parse command line arguments to check for --test flag
    for arg in "$@"; do
        if [[ "$arg" == "--test" ]]; then
            set_environment_mode "test"
            break
        fi
    done
    
    # Use environment-aware path functions
    local target_file="$(get_zshrc_path)"
    local global_path="$(get_global_commands_path)"
    local local_path="$(get_local_commands_path)"
    
    # Set marker comment based on environment
    if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
        local marker_comment="Source shell command manager files (TEST VERSION)"
        echo "Installing in TEST mode - files will be created in project folder"
    else
        local marker_comment="Source shell command manager files"
        echo "Installing in PRODUCTION mode - modifying actual .zshrc"
    fi
    
    # Ensure directories exist
    mkdir -p "$(dirname "$global_path")"
    mkdir -p "$(dirname "$local_path")"
    
    # Define the lines that will be added to the target file
    local source_lines=(
        "# $marker_comment"
        "[ -f \"$global_path\" ] && source \"$global_path\""
        "[ -f \"$local_path\" ] && source \"$local_path\""
    )
    
    # Check if the target file doesn't exist OR doesn't already contain our marker comment
    if ! [ -f "$target_file" ] || ! grep -q "$marker_comment" "$target_file"; then
        # Add a blank line for spacing
        echo "" >> "$target_file"
        
        # Write each line from the source_lines array to the target file
        printf "%s\n" "${source_lines[@]}" >> "$target_file"
        
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Added source lines to zshrc_test file in project folder."
        else
            echo "Added source lines to .zshrc and sourced it."
            source "$target_file"
        fi
    else
        # The lines are already present, so don't add them again
        if [[ "$ENVIRONMENT_MODE" == "test" ]]; then
            echo "Source lines already present in zshrc_test."
        else
            echo "Source lines already present in .zshrc."
        fi
    fi
}