<div align="center">
    <h1>
        <img src="https://gitlab.com/raggesilver-proton/proton/raw/master/data/icons/hicolor/scalable/apps/com.raggesilver.Proton.svg" /> Proton
    </h1>
    <h4>A soon-to-be IDE</h4>
    <p>
        <a href="https://gitlab.com/raggesilver-proton/proton/pipelines">
            <img src="https://gitlab.com/raggesilver-proton/proton/badges/master/pipeline.svg" alt="Build Status" />
        </a>
        <a href="https://www.patreon.com/raggesilver">
            <img src="https://img.shields.io/badge/patreon-donate-orange.svg?logo=patreon" alt="Proton on Patreon" />
        </a>
    </p>
    <p>
        <a href="#install">Install</a> •
        <a href="#features">Features</a> •
        <a href="https://gitlab.com/raggesilver-proton/proton/blob/master/COPYING">License</a>
    </p>
</div>

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
