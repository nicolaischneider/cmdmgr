# Command Manager

The repo for the official killer command manager to make the management of the many cool ass commands we have easier then ever.

## Todos
- [ ] Global folder should include README
- [ ] add imported from github command: should cd into empty global folder, then ask for git clone url
- [ ] option for first upload to github
- [ ] option for commit and push to github, add param to create function to push to github
- [ ] improve install to show people usage by creating a new function cm to call `cmdmgr`
- [ ] last task: the tool should be installed on the system such that we cann call `cmdmgr` from anywhere

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