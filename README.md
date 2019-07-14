# Proton

Proton is a simple text editor, soon-to-be IDE.

![Preview](https://imgur.com/efOlmZ5.png)

## Install
```bash
flatpak-builder --install --user --force-clean _build com.raggesilver.Proton.json
```

## Features
- Integrated terminal
- Plugin system (all [../proton-*-plugin](https://gitlab.com/raggesilver-proton/) are core plugins)
- Overlay command palette + file discover

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

## Other screenshots

| Welcome window | Preferences window |
| --- | --- |
| ![preview](https://imgur.com/ezTDdnt.png) | ![preview](https://imgur.com/DOun2WI.png) |
