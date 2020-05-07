<div align="center">
    <h1>
        <img src="https://gitlab.com/raggesilver-proton/proton/raw/proton2/data/icons/hicolor/scalable/apps/com.raggesilver.Proton.svg" /> Proton
    </h1>
    <h4>A native IDE for Linux</h4>
    <p>
        <a href="https://gitlab.com/raggesilver-proton/proton/pipelines">
            <img src="https://gitlab.com/raggesilver-proton/proton/badges/proton2/pipeline.svg" alt="Build Status" />
        </a>
        <a href="https://www.patreon.com/raggesilver">
            <img src="https://img.shields.io/badge/patreon-donate-orange.svg?logo=patreon" alt="Proton on Patreon" />
        </a>
    </p>
    <p>
        <a href="#install">Install</a> •
        <a href="#features">Features</a> •
        <!-- <a href="#features">Features</a> • -->
        <a href="https://gitlab.com/raggesilver-proton/proton/blob/proton2/LICENSE">License</a>
    </p>
</div>

> THIS IS A REWORK BRANCH, NOTHING HERE IS EXPECTED TO WORK UNTIL IT IS
> MERGED INTO MASTER.
>
> Read more about the rewrite [here](https://www.patreon.com/posts/proton-rewrite-36815536)

<div align="center">
    <img src="https://imgur.com/yw2EpLI.png" alt="Preview"/>
</div>

This is a preview of the new layout. Editors will look the same, but this
time we'll have a working grid system.

## Features

<div align="center">
Wow, such empty!
</div>

## Install

**Download**

[Flatpak](https://gitlab.com/raggesilver-proton/proton/-/jobs/artifacts/proton2/raw/proton.flatpak?job=build) • [Zip](https://gitlab.com/raggesilver-proton/proton/-/jobs/artifacts/proton2/download?job=build)

*Note: these two links might not work if the latest pipeline failed/is still running*

**Flathub**

> Flathub releases will be available once Proton hits version 1.0.0.

## Compile

> Proton can be compiled on GNOME Builder. If you have Proton
> (0.1.8~0.3.0) you can also run Proton on Proton 😜️. (for either one
> just press play and behold magic)

**Flatpak**

```bash
# Clone the repo
git clone --recursive https://gitlab.com/raggesilver-proton/proton
# cd into the repo
cd proton
# Assuming you have make, flatpak and flatpak-builder installed
# Makefile has a few useful rules that will build and install Proton as a
# flatpak locally on ./app_build and ./app
make run
# You can also
# make [command]
#
#   update      - update outdated dependencies
#   hard-update - remove and update all dependencies
#   export      - export proton as a flatpak. Generates ./proton.flatpak
#   install     - runs `export` then `flatpak install --user proton.flatpak`
#   clean       - cleans build files
#   fclean      - cleans build files and dependencies
#   ffclean     - cleans build files, dependencies and .flatpak-builder
```

**Regular (unsupported)**

Building Proton from source without Flatpak is possible, but I won't spend
my time debugging user mismatched dependency versions.

```bash
# Clone the repo
git clone --recursive https://gitlab.com/raggesilver-proton/proton
# cd into the repo
cd proton
meson _build
ninja -C _build
# sudo
ninja -C _build install
proton
```

## UI Mocks

<div align="center">
Wow, such empty!
</div>

## Credits

Code derived/based on other projects is properly attributed on each file.

Thanks @gavr123456789 for being a [Patron](https://patreon.com/raggesilver)
for over 4 months.
