#!/bin/bash

MODULE="proton"
MANIFEST="com.raggesilver.Proton.json"

if [[ $# -ge 1 ]]; then

    case $1 in

        "update")
            echo "Run update";
            flatpak-builder --ccache --force-clean --download-only --stop-at=$MODULE app $MANIFEST
            flatpak-builder --ccache --force-clean --disable-updates --disable-download --stop-at=$MODULE app $MANIFEST
            ;;

        *)
            echo "Invalid option $1";
            exit 1;
            ;;
    esac
    exit 0;
fi

if [ ! -d "app" ]; then
  flatpak-builder --stop-at=$MODULE app $MANIFEST || exit $?
fi

if [ ! -d "app_build" ]; then
  flatpak-builder --run app $MANIFEST meson --prefix=/app app_build || exit $?
fi

flatpak-builder --run app $MANIFEST ninja -C app_build || exit $?
flatpak-builder --run app $MANIFEST ninja -C app_build install || exit $?
flatpak-builder --run app $MANIFEST $MODULE || exit $?
