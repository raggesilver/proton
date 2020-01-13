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

![Preview](https://imgur.com/VpePB31.png)

## Features
- Integrated terminal
- Plugin system (all [../proton-*-plugin](https://gitlab.com/raggesilver-proton/) are core plugins)
- Overlay command palette + file discover
- [Build system](https://gitlab.com/raggesilver-proton/proton-runner-plugin)
- New project [templates](https://gitlab.com/raggesilver-proton/proton-templates)
- Clone existing projects from a Git repo

## Install

**Download**

[Flatpak](https://gitlab.com/raggesilver-proton/proton/-/jobs/artifacts/master/raw/proton.flatpak?job=deploy) • [Zip](https://gitlab.com/raggesilver-proton/proton/-/jobs/artifacts/master/download?job=deploy)

*Note: these two links might not work if the latest pipeline failed/is still running*

**Flathub**

> Flathub releases will be available once Proton hits version 1.0.0.

## Compile

> Proton can be run on GNOME Builder. If you have Proton 0.1.8+ you can also
> run Proton on Proton 😜️. (for either one just press play and behold magic)

**Flatpak from source**

```bash
# Clone the repo
git clone --recursive https://gitlab.com/raggesilver-proton/proton
# cd into the repo
cd proton
# Assuming you have both flatpak and flatpak-builder installed
# test.sh has a few useful scripts that will build and install proton as a
# flatpak locally on ./app_build and ./app
sh test.sh
# You can also
# sh test.sh [command]
#
#   update - update all flatpak dependencies
#   export - export proton as a flatpak. Generates ./proton.flatpak and ./repo
```

**Regular from source (unsupported)**

```bash
# Clone the repo
git clone --recursive https://gitlab.com/raggesilver-proton/proton
# cd into the repo
cd proton
meson _build
ninja -C _build
# sudo
ninja -C _build install
```

## Gallery

> These pictures are rarely updated (might be outdated)

| Welcome window | Preferences window |
| -------------- | ------------------ |
| ![](https://imgur.com/ezTDdnt.png) | ![](https://imgur.com/DOun2WI.png) |

## Credits

Code derived/based on other projects is properly attributed on each file.


