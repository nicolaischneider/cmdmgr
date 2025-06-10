#!/bin/bash

# Source path configuration
source "$(dirname "${BASH_SOURCE[0]}")/paths.sh"

install() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local zshrc_test="$script_dir/zshrc_test"
    local source_lines=(
        "# Source shell command manager files"
        "[ -f \"$GLOBAL_COMMANDS_PATH\" ] && source \"$GLOBAL_COMMANDS_PATH\""
        "[ -f \"$LOCAL_COMMANDS_PATH\" ] && source \"$LOCAL_COMMANDS_PATH\""
    )
    
    if ! [ -f "$zshrc_test" ] || ! grep -q "Source shell command manager files" "$zshrc_test"; then
        echo "" >> "$zshrc_test"
        printf "%s\n" "${source_lines[@]}" >> "$zshrc_test"
        echo "Added source lines to zshrc_test file."
    else
        echo "Source lines already present in zshrc_test."
    fi
}