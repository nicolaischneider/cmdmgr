# Command Manager

A bash-based command manager designed to help developers and power users create, organize, and manage custom shell commands efficiently. This tool eliminates the need to clutter your `.zshrc` file with countless aliases and functions by providing a structured way to organize commands into global and local scopes.

Whether you're managing personal productivity scripts, team-shared utilities, or project-specific commands, Command Manager provides an intuitive interface for creating, editing, and syncing your command library across different machines through git integration.

## Installation

1. Clone this repository and install the command manager:
```bash
git clone <your-repo-url>
cd cmdmgr
./cmdmgr.sh install
```

2. Reload your shell:
```bash
source ~/.zshrc
```

## Usage

### Command Operations

**Create** - Create a new command interactively
```bash
cmdmgr create
```

**List** - List all available commands
```bash
cmdmgr list
```

**Delete** - Delete an existing command
```bash
cmdmgr delete
```

**Edit** - Edit command files with specified editor
```bash
cmdmgr edit        # Uses vim by default
cmdmgr edit nano   # Use nano editor
```

**Import** - Import existing functions and aliases from .zshrc
```bash
cmdmgr import
```

**Uninstall** - Remove all commands and configuration
```bash
cmdmgr uninstall
```

### Global Commands Directory

**Where Global** - Print path to global commands directory
```bash
cmdmgr where-global
```

**Pull Global** - Pull latest changes from git in global commands directory
```bash
cmdmgr pull-global
```

**Push Global** - Add, commit and push changes in global commands directory
```bash
cmdmgr push-global
```

## Command Storage

- **Global commands**: `$HOME/.shell-commands/global/global-commands.sh`
- **Local commands**: `$HOME/.shell-commands/local-commands.sh`
- Commands are stored as bash functions that get sourced by your shell

## Git Integration

The global commands directory can be initialized as a git repository to sync commands across machines:

```bash
# Navigate to global directory
# Use `cmdmgr where-global` to access the path

# Initialize git repo
git init
git remote add origin <your-repo-url>

# Now you can use pull-global and push-global commands
cmdmgr pull-global
cmdmgr push-global
```

## Todos
- [x] last task: the tool should be installed on the system such that we cann call `cmdmgr` from anywhere

## Fixes
- [ ] import not working as expected (importing everything somehow and also commenting is failing)
- [ ] when uninstalling it should not offer to open the files but instead iopen the folder in finder/the explorer through `open <path>`

## Future Scope
- [ ] add imported from github command: should cd into empty global folder, then ask for git clone url
- [ ] option for first upload to github
- [ ] option for commit and push to github, add param to create function to push to github
- [ ] improve install to show people usage by creating a new function cm to call `cmdmgr`