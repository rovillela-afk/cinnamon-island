#!/bin/bash
# Builds the Cinnamon Island packages in dist/:
#   - cinnamon-island@rovillela.zip: the extension with the engine inside, to
#     install by hand or submit to the Cinnamon store (Cinnamon Spices);
#   - spices/cinnamon-island@rovillela/: the same thing in the folder layout
#     the store repository asks for;
#   - cinnamon-island_VERSION_all.deb: extension and engine installed
#     system-wide, with the engine as a user service.
set -e

UUID="cinnamon-island@rovillela"
ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$ROOT/extension/$UUID/metadata.json")"
DIST="$ROOT/dist"

rm -rf "$DIST"
mkdir -p "$DIST"

copy_engine() {  # copies the engine without the Python caches
    mkdir -p "$1"
    cp "$ROOT"/engine/cinnamon_island_engine/*.py "$1/"
}

# --- extension with the engine bundled ----------------------------------------
EXT="$DIST/spices/$UUID/files/$UUID"
mkdir -p "$EXT"
cp -r "$ROOT/extension/$UUID/." "$EXT/"
copy_engine "$EXT/engine/cinnamon_island_engine"
cp "$ROOT/LICENSE" "$EXT/"
# The store shows this README; it must not point to downloads outside the store.
cp "$ROOT/STORE.md" "$DIST/spices/$UUID/README.md"
[ -f "$ROOT/screenshot.png" ] && cp "$ROOT/screenshot.png" "$DIST/spices/$UUID/"
cat > "$DIST/spices/$UUID/info.json" <<END
{
    "author": "${CINNAMON_ISLAND_GITHUB_AUTHOR:-rovillela-afk}"
}
END
(cd "$DIST/spices/$UUID/files" && zip -qr "$DIST/$UUID.zip" "$UUID")

# --- .deb package -------------------------------------------------------------
DEB="$DIST/deb"
mkdir -p "$DEB/DEBIAN" "$DEB/usr/share/cinnamon/extensions" "$DEB/usr/lib/systemd/user" "$DEB/usr/share/doc/cinnamon-island"
cp -r "$ROOT/extension/$UUID" "$DEB/usr/share/cinnamon/extensions/"
copy_engine "$DEB/usr/lib/python3/dist-packages/cinnamon_island_engine"
cp "$ROOT/LICENSE" "$DEB/usr/share/doc/cinnamon-island/copyright"
# Translations for the settings window.
for po in "$ROOT/extension/$UUID"/po/*.po; do
    language="$(basename "$po" .po)"
    mkdir -p "$DEB/usr/share/locale/$language/LC_MESSAGES"
    msgfmt "$po" -o "$DEB/usr/share/locale/$language/LC_MESSAGES/$UUID.mo"
done
cat > "$DEB/usr/lib/systemd/user/cinnamon-island-engine.service" <<END
[Unit]
Description=Cinnamon Island engine

[Service]
# Without this, Python would also look for modules in the folder it was
# started from (the home folder), ahead of the system ones.
Environment="PYTHONSAFEPATH=1"
ExecStart=/usr/bin/python3 -m cinnamon_island_engine
Restart=on-failure
RestartSec=2
END
cat > "$DEB/DEBIAN/control" <<END
Package: cinnamon-island
Version: $VERSION
Section: x11
Priority: optional
Architecture: all
Depends: python3 (>= 3.9), python3-gi, gir1.2-gtk-3.0, pulseaudio-utils, cinnamon (>= 6.0)
Recommends: python3-dateutil
Maintainer: Rodrigo Villela <villelainfa@hotmail.com>
Description: Dynamic island for the Cinnamon desktop
 A glass notch on the screen edge that expands into tabs: volume, media,
 clock, agenda, notes, clipboard, files, weather, notifications, system and
 tools.
END
# No install scripts: the island itself starts the engine service.
dpkg-deb --root-owner-group --build "$DEB" "$DIST/cinnamon-island_${VERSION}_all.deb" >/dev/null
rm -rf "$DEB"

echo "Packages in $DIST:"
ls -1 "$DIST"
