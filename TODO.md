# TODO

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
using `.gitignore` would be gold.
