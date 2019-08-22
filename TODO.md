# TODO

## Todos
1. Right click popover on `TreeView`
3. `PreferencesWindow` (WIP [src/preferences_window.vala](https://gitlab.com/raggesilver-proton/proton/blob/master/src/preferences_window.vala))
4. Plugins: 42, git, ~~run~~ -> runner (WIP [proton-runner-plugin](https://gitlab.com/raggesilver-proton/proton-runner-plugin))
6. Finish `OpenWindow`[^1]

- ~~Finish terminal widget~~ Fair base widget for terminal use. Needs improvement
- ~~Command palette~~ Works reasonably well
- ~~File modified characted on the window title (e.g "Proton - filename.c •")~~
- ~~Prevent app quiting when modified editors are still open~~
- ~~TreeView updates~~

## CommandPalette

Apart from actually creating a proper command palette, finding files needs a
rework. The issue is that it currently finds compiled files and the quick fix
`find ... -exec grep -Iq . {} \; -print` makes the command take way longer to
index the files, making it unusable.

A possible way to fix this is by indexing the text files as soon as the IDE
starts and reindexing once there is a change in the folder.

Note: the command `file <filename>` outputs information of the given file. Valid
text files contain ASCII and/or {'text', 'empty'}.

Note 2: having the option to manually set exclude patterns for indexing and
using `.gitignore` would be good.

## OpenWindow

Since [58ba5efb](https://gitlab.com/raggesilver-proton/proton/commit/58ba5efb6893178f9514a3d381919d6b58915001)
I began working on cloning existing repos from a remote location. That still
has a lot of bugs which may cause the entire program to crash.

Templates should also be created. Templating needs design and further planning
to maybe load templates from a file.
