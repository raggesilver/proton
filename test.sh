#!/bin/bash

MODULE="proton"
MANIFEST="com.raggesilver.Proton.json"

if [ ! -d "app" ]; then
  flatpak-builder --stop-at=$MODULE app $MANIFEST || exit $?
fi

if [ ! -d "app_build" ]; then
  flatpak-builder --run app $MANIFEST meson --prefix=/app app_build || exit $?
fi

flatpak-builder --run app $MANIFEST ninja -C app_build || exit $?
flatpak-builder --run app $MANIFEST ninja -C app_build install || exit $?
flatpak-builder --run app $MANIFEST $MODULE || exit $?
