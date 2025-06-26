#!/bin/bash

# Git Operations Module
# Contains functions for git operations on global commands directory

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