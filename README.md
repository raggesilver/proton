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

## Features
- Integrated terminal
- Plugin system (all [../proton-*-plugin](https://gitlab.com/raggesilver-proton/) are core plugins)
- Overlay command palette + file discover

## Install

**Download**

[Flatpak](https://gitlab.com/raggesilver-proton/proton/-/jobs/artifacts/master/raw/proton.flatpak?job=deploy) • [Zip](https://gitlab.com/raggesilver-proton/proton/-/jobs/artifacts/master/download?job=deploy)

*Note: these two links might not work if the latest pipeline failed/is still running*

**Flathub**

> Flathub releases will be available once Proton hits version 1.0.0.

## Compile

**Flatpak from source**

```bash
# Clone the repo
git clone --recursive https://gitlab.com/raggesilver-proton/proton
# cd into the repo
cd proton
# Assuming you have both flatpak and flatpak-builder installed
flatpak-builder --install --user --force-clean _build com.raggesilver.Proton.json
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

*Note: Proton can be ran from GNOME Builder*

## Gallery

Welcome window
<img src="https://imgur.com/ezTDdnt.png" /> <br>
Settings window
<img src="https://imgur.com/DOun2WI.png" />
