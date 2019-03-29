# Proton

Proton is a simple text editor, soon-to-be IDE.

<br />

![Preview](preview.png)

## Compile / Install
Use `flatpak` or `meson` (ninja) to install or compile Proton.

## Features worth sharing
- Integrated terminal
- Editorconfig plugin

## Todos <span style="font-size: 10pt">(sorted by importance)</span>
1. ~~File modified characted on the window title (e.g "Proton - filename.c •")~~
2. ~~Prevent app quiting when modified editors are still open~~
3. TreeView updates - ongoing
4. File operations
	- [ ] New File
	- [ ] New Folder
	- [ ] Rename
	- [ ] Move
	- [ ] Delete
5. ~~Open project~~
    - Working on new widget `OpenWindow`[^1]
    - Clone repo - pending
    - New project - pending
    - Open project - done
6. Run project
7. Command palette
8. Preferences menu
9. ~~Plugins~~
    - Basic suport for loading plugins added
    - Plugins have to be compiled with `proton` (more or less)

---

[^1]: ![preview](https://imgur.com/axVOeZv.png)