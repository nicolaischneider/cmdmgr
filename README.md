# Command Manager

The repo for the official killer command manager to make the management of the many cool ass commands we have easier then ever.

## Todos

- [ ] each command description should be added as a comment above a function
- [ ] get rid of list file and access everything through G and L files and separate in print
- [ ] import existing commands from zshrc file
- [ ] Gloabl folder should include README
- [ ] add update command in case commands have been imported from github (all names and descriptions should be added respectfully)
- [ ] improve install to show people usage by creating a new function cm to call `cmdmgr`
- [ ] last task: the tool should be installed on the system such that we cann call cmdmgr from anywhere

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