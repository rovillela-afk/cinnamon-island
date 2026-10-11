#!/bin/bash
# Installs the engine as a user service and the extension through a symbolic
# link (so edits in the project folder take effect on the next run), then
# reloads both.
# Usage: ./install.sh [--island-only | --remove]
set -e

UUID="cinnamon-island@rovillela"
ROOT="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$ROOT/extension/$UUID"
TARGET="$HOME/.local/share/cinnamon/extensions/$UUID"
ENGINE="$ROOT/engine"
SERVICE="cinnamon-island-engine.service"
UNIT="$HOME/.config/systemd/user/$SERVICE"

enabled() { gsettings get org.cinnamon enabled-extensions; }

if [ "$1" = "--remove" ]; then
    gsettings set org.cinnamon enabled-extensions "$(enabled | python3 -c "import ast,sys; print([u for u in ast.literal_eval(sys.stdin.read().replace('@as ', '')) if u != '$UUID'])")"
    rm -f "$TARGET"
    systemctl --user disable --now "$SERVICE" 2>/dev/null || true
    rm -f "$UNIT"
    systemctl --user daemon-reload
    echo "Cinnamon Island removed."
    exit 0
fi

# Engine: a user service that runs straight from the project folder.
mkdir -p "$(dirname "$UNIT")"
cat > "$UNIT" <<END
[Unit]
Description=Cinnamon Island engine

[Service]
# Without this, Python would also look for modules in the folder it was
# started from (the home folder), ahead of the system ones.
Environment="PYTHONSAFEPATH=1"
Environment="PYTHONPATH=$ENGINE"
ExecStart=/usr/bin/python3 -m cinnamon_island_engine
Restart=on-failure
RestartSec=2
END
# The service is never "enabled": the island starts it when it loads. The
# Cinnamon session does not activate graphical-session.target, so the service
# would never start by itself at login.
systemctl --user disable "$SERVICE" >/dev/null 2>&1 || true
systemctl --user daemon-reload
# With --island-only the engine is not restarted, so a running Pomodoro or
# timer and the clipboard history are kept. Use it when only the extension
# changed.
if [ "$1" != "--island-only" ]; then
    systemctl --user restart "$SERVICE"
fi

mkdir -p "$(dirname "$TARGET")"
ln -sfn "$SOURCE" "$TARGET"

# Translations: compile each po/*.po into ~/.local/share/locale
for po in "$SOURCE"/po/*.po; do
    language="$(basename "$po" .po)"
    mkdir -p "$HOME/.local/share/locale/$language/LC_MESSAGES"
    # Replace the file in one step: Cinnamon keeps the old .mo mapped.
    mo="$HOME/.local/share/locale/$language/LC_MESSAGES/$UUID.mo"
    msgfmt "$po" -o "$mo.new" && mv -f "$mo.new" "$mo"
done

if enabled | grep -q "$UUID"; then
    dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon \
        org.Cinnamon.ReloadXlet string:"$UUID" string:"EXTENSION"
    # Cinnamon caches the computed style of each widget; without reloading the
    # theme, stylesheet.css changes do not reach widgets that already existed.
    # It has to go through the theme manager, which rebuilds the theme and
    # tells every extension and applet to reload its stylesheet. Calling
    # Main.loadTheme() alone rebuilds the theme without anyone's stylesheet.
    sleep 1
    gdbus call --session --dest org.Cinnamon --object-path /org/Cinnamon \
        --method org.Cinnamon.Eval "Main.themeManager._changeTheme()" >/dev/null
    echo "Cinnamon Island reloaded."
else
    gsettings set org.cinnamon enabled-extensions "$(enabled | python3 -c "import ast,sys; print(ast.literal_eval(sys.stdin.read().replace('@as ', '')) + ['$UUID'])")"
    echo "Cinnamon Island installed and enabled."
fi
