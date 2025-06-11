# Command Manager

The repo for the official killer command manager to make the management of the many cool ass commands we have easier then ever.

## Todos
- [ ] last task: the tool should be installed on the system such that we cann call `cmdmgr` from anywhere
- [ ] Finalize README with proper description and detailed usage explanation

## Future Scope
- [ ] add imported from github command: should cd into empty global folder, then ask for git clone url
- [ ] option for first upload to github
- [ ] option for commit and push to github, add param to create function to push to github
- [ ] improve install to show people usage by creating a new function cm to call `cmdmgr`

## Done
- [x] basic script to create new commands
- [x] help function to view comamnds
- [x] management of global and local file
- [x] test env to play around with implementations
- [x] delete commands
- [x] add option to download script and add linking to `.zshrc` file
- [x] add option to edit directly
- [x] simulate separate .zshrc file in same folder of code
- [x] extract path to where stuff is stored to new file
- [x] each command description should be added as a comment above a function
- [x] get rid of list file and access everything through G and L files and separate in print
- [x] import existing commands from zshrc file
- [x] Option to cd into (optionally empty) global folder
- [x] Option to pull/push latest changes from global folder