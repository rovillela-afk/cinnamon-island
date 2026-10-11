# Cinnamon Island

A dynamic island for the Cinnamon desktop: a glass notch against the screen edge that expands into tabs. What is done, the decisions and the known limits are in [PLAN.md](PLAN.md); read it before changing anything.

The app is called **Cinnamon Island** (uuid `cinnamon-island@rovillela`). In the code, "island" is the widget itself (class `Island`, style classes `island-*`). The author works in Brazilian Portuguese: talk to him in Portuguese, but write code, comments, commit messages and documents in English.

## Project rules

- One change at a time, checked on screen before the next. When you finish something that changes what the app does, update PLAN.md (what is done, decisions, limits) and, if it touches the network or the person's data, SECURITY.md.
- Target environment: Linux Mint, Cinnamon 6.x, X11 session. Wayland is for later.
- The extension only draws. All logic (MPRIS, audio, Pomodoro, etc.) goes in the Python engine (`engine/`), which talks to the extension over D-Bus.
- Everything in the repository is in English: file names, identifiers, comments and documents. The only Portuguese is the translation in `po/pt_BR.po` and `README.pt-BR.md`.
- Visible strings are English in the code, inside `_()`, with the translation in `po/pt_BR.po`. Every new string needs its `.po` entry.
- Colour is a detail, not a theme: use only the four colours of `COLORS` in `util.js`, on small things and with meaning. Blue is sound (and rain); green is microphone and "active"; yellow is application, timer and sun; rose is mute and alert. Texts, numbers and buttons stay white or grey; the knob of the sliders is always white. No purple and no colour on everything.
- The island never steals keyboard focus when opened with the mouse. It grabs the keyboard (Cinnamon modal) in two cases only: a text field the person clicked, and when it was opened by the shortcut. Always use `_grabKeyboard()`/`_releaseKeyboard()`, which count the requests; never call `Main.pushModal` directly. Every path that closes the island has to release the modal.

## Structure

- `extension/cinnamon-island@rovillela/`: the Cinnamon extension. `extension.js` is the island itself (shape, animation, tabs); `engine.js` is the D-Bus client of the engine; each tab has its file (`tabVolume.js`, `tabMusic.js`, `tabPomodoro.js` and `tabTime.js` (the Clock tab combines Pomodoro, timer and stopwatch), `tabFiles.js`, `tabNotes.js`, `tabClipboard.js`, `tabSystem.js`, `tabWeather.js`, `tabAgenda.js`, `tabTools.js`, `tabInbox.js`); `slider.js` is the slider and `ruler.js` is the minute ruler (used by the timer and the Pomodoro); `collapsed.js` is what shows while the island is closed. Files import each other with `require('./name')` and export with `module.exports`.
- `engine/cinnamon_island_engine/`: the Python engine (PyGObject only, no extra dependencies). `service.py` is the base of a tab; `music.py`, `volume.py`, `pomodoro.py`, `files.py`, `notes.py`, `clipboard.py`, `system.py` and `weather.py` (weather and agenda) are the tabs; `timer.py` is the timer and the stopwatch, which share the tab with the Pomodoro; `lyrics.py` fetches song lyrics and `spectrum.py` measures the sound for the wave bars (both serve the Media tab); `tools.py` is the Tools tab and `camera.py` is the camera mirror it opens; `inbox.py` is the Notifications tab (it listens to system notifications through a D-Bus monitor connection; interface `.Inbox`); `net.py` is where every download goes through (http/https only, with a size cap): do not use `urllib` directly. `notices.py` is not a tab: it produces the notices the island shows while collapsed (downloads, Bluetooth, battery).
- `tools/capture.py`: captures a piece of the real screen to check the looks.
- `screenshots/`: the pictures the README shows, in English, with the Portuguese set in `screenshots/pt-BR/`. `screenshot.png` at the root is the one the Cinnamon store uses. Retake them with `tools/capture.py` (region `780 0 1000 340` on a 2560 px wide screen) when a tab changes its looks; never capture tabs with personal content (Agenda, Notes, Clipboard, Files, Weather, Notifications).
- `install.sh`: installs the engine as a user service (`cinnamon-island-engine.service`), creates the extension link in `~/.local/share/cinnamon/extensions/`, compiles the translations and reloads everything. `./install.sh --remove` undoes it.
- `package.sh`: builds in `dist/` the extension .zip with the engine inside, the folder in the Cinnamon store layout and the .deb. The version comes from `metadata.json`.

## Engine

- D-Bus name: `org.cinnamonisland.Engine`, object `/org/cinnamonisland/Engine`, one interface per tab (`org.cinnamonisland.Engine.Music`, `.Volume`, `.Pomodoro`, `.Timer`, `.Files`, `.Notes`, `.Clipboard`, `.System`, `.Weather`, `.Tools`, `.Inbox`, `.Lyrics`), plus `.Notices` for the notices.
- Every tab has `GetState() -> s` (JSON), the `StateChanged(s)` signal and its commands. To create a tab, inherit from `Service`, declare `INTERFACE` and `METHODS`, implement `do_<Command>` and call `set_state()`; then register it in `__main__.py` and in `TABS` in `engine.js`.
- See the state: `gdbus call --session --dest org.cinnamonisland.Engine --object-path /org/cinnamonisland/Engine --method org.cinnamonisland.Engine.Music.GetState`.
- The engine does not start by itself at login: the Cinnamon session does not activate `graphical-session.target`, so `WantedBy` on that target never fires. The island is what starts the engine (`_startEngine()` in `engine.js`), with `systemctl --user start` or by launching the bundled engine.
- Engine log: `journalctl --user -u cinnamon-island-engine.service -f`.
- Data files: `~/.local/share/cinnamon-island/` (`notes.txt`, `files.json`, `pomodoro.json`, `pomodoro-session.json`, `last_track.json`), `~/.config/cinnamon-island/` (`weather.json`, `lyrics.json`, `pomodoro.json`) and `~/.cache/cinnamon-island/` (`covers/`, `lyrics/`).

## How to test

- After any change to the extension or the engine, run `./install.sh` and look for errors with `tail -f ~/.xsession-errors` or in Looking Glass (Alt+F2, `lg`).
- To check the looks, use `tools/capture.py X Y WIDTH HEIGHT out.png`. Do not use gnome-screenshot to judge the glass: it shows the blur lagging behind the screen.
- To see a download notice, create a file in `~/Downloads` the way browsers do: `echo x > ~/Downloads/t.pdf.part && mv ~/Downloads/t.pdf.part ~/Downloads/t.pdf` (and delete it afterwards).
- To see a system notification, use `notify-send -a Firefox "Title" "Text"`.
- The island actor keeps its instance in `_delegate`: through `Eval` you can call, for example, `actor._delegate._selectTab('Pomodoro')`. To keep it open while you look: `i._pinned = true; i._setExpanded(true)`.
- To test the Pomodoro quickly, send short durations straight to the engine (`Pomodoro.Configure '{"focus_minutes": 0.1, "sound": false, "pause_music": false}'`) and run `./install.sh` at the end to go back to the real preferences. The test adds focus rounds to the real statistics; clean `~/.local/share/cinnamon-island/pomodoro.json` afterwards.
- The island can be inspected without a mouse over D-Bus: `gdbus call --session --dest org.Cinnamon --object-path /org/Cinnamon --method org.Cinnamon.Eval '<js>'`. The actor is the child of `Main.uiGroup` with `style_class == "island"`; assigning `hover = true` simulates the mouse.
- Cinnamon does not watch the settings file in `~/.config/cinnamon/spices/cinnamon-island@rovillela/`. Changes made outside the settings window only apply after calling `org.Cinnamon.updateSetting` or reloading the extension.

## Cinnamon quirks

- The glass blur comes from St's `background-blur` CSS property (number of passes, respects `border-radius`). `St.BackgroundBlurEffect` added by hand with `add_effect` does nothing.
- St builds the corner mask of the blur only once. Whenever the size or the radius of the glass changes, remove and re-add `background-blur` in the style (that is what `_applyGlass()` does).
- St only rounds corners outwards. The concave curves of the notch are drawn with Cairo in an `St.DrawingArea` and have no blur.
- `St.Bin` and `St.Button` have their own `x_align`/`y_align` (of type `St.Align`), different from Clutter's. To align a widget inside a `BoxLayout`, use an `St.Widget` with `BinLayout`.
- Inside a `BinLayout`, `margin_left`/`margin_top` passed to the constructor do not move the child. For a fixed position, put the child in an `St.Widget` with `Clutter.FixedLayout` and use `set_position`.
- Texts are translated through gettext, like any spice (`bindTranslations()` in `util.js`), using the `.mo` that `install.sh`, the .deb or the store compile from `po/`. Cinnamon keeps a loaded `.mo` until it restarts, so a new string may show in English until then. Only when the person picks a language in the settings is `po/<language>.po` read directly, asynchronously, and the island rebuilt.
- The extension does no blocking file or D-Bus I/O (a rule of the Cinnamon store): use the `_async` variants. `po/cinnamon-island@rovillela.pot` is the translation template; regenerate it when strings change. `STORE.md` is the README the store shows.
- The island uses the font of the Cinnamon theme; it ships no font of its own (the store takes no binary files, and every package is meant to be identical). If a font family list is ever needed in the stylesheet, write it without quotes: with quoted names St silently drops the first family.
- The JSON output of `pactl` 16 fails on accented names; the engine parses the text output with `LC_ALL=C`.
- `Clutter.grab_pointer`/`ungrab_pointer` do not exist here. To grab the mouse during a drag, use `event.get_device().grab(actor)` and `.ungrab()`.
- Extensions do not receive drag and drop from other programs (XDND). The file shelf solves it with an invisible GTK window of the engine under the island and a "hole" in the input region: the island's input region is made of pieces (`_inputPieces`) registered with `trackChrome`, and `_syncShelf()` rearranges them around the shelf. The island and the window have to agree on the layout: files left to right, each with the engine's `CELL` width, and the remove button in the `CLOSE` square of each cell.
- `Main.xdndHandler` calls `handleDragOver` on the actor's `_delegate` when an external drag passes over it; the island also checks the drag position itself through a `DND` drag monitor. That is how it opens on the Files tab.
- The Pomodoro is resumed after an engine restart (it is saved in `pomodoro-session.json`). The timer, the stopwatch, the clipboard history and the notification inbox are still lost.
- If only the extension changed, run `./install.sh --island-only`: it reloads the island without restarting the engine, so whatever is in progress (Pomodoro, timer, clipboard history) carries on. Before restarting the engine, check whether a Pomodoro or a timer is running.
- Running `./install.sh` restarts the engine and rebuilds the island: someone typing a note loses what was in progress.
- St caches the computed style of each widget (by class and position in the tree). Reloading only the extension keeps the old styles; that is why `install.sh` calls `Main.themeManager._changeTheme()` after reloading. Never call `Main.loadTheme()` directly: it rebuilds the theme without the stylesheets of extensions and applets, leaving the island (and the rest of Cinnamon) unstyled.
- The island actor is wider than the glass body: on each side there is a strip (`m.gutter`) where the tab orbs live. Anything that positions things on the body has to add that strip (see `bodyX`/`bodyY` in `_relayout()` and `g` in `_drawShape()`).
- To swap one content for another, use `rollSwitch()` from `util.js`; it takes care of hiding the old one and of undoing the animation if it is interrupted.
- Lists that scroll with the wheel return `EVENT_STOP` only when they actually moved; at the start, at the end or when everything fits, they return `EVENT_PROPAGATE` so the island switches tabs.
- To put something on the clipboard from the engine, send the text in a notice with the `copy` field: the island is the one that copies (`St.Clipboard`).
- A control that uses the mouse wheel needs three things: handle `scroll-event` returning `Clutter.EVENT_STOP` (otherwise the island switches tabs), `track_hover: true` and the `island-wheel` class (so it lights up under the mouse).
- Redrawing only a piece of the island leaves a darker rectangle in the blur. The `queue-redraw` signal of the island actor forces the whole glass to be redrawn whenever something inside it changes.
- Opening a notification is done by the extension, not the engine (`_open()` in `tabInbox.js`): it clicks Cinnamon's own copy in `Main.notificationDaemon._notifications` when it still exists, otherwise it activates the windows of the `Cinnamon.App` it remembered when the notification arrived (Cinnamon identifies the sender by process, which is more reliable than the reported name).
- The filter of the D-Bus monitor connection in `inbox.py` must let through everything that is not `Notify`. If it swallows the reply to `BecomeMonitor` itself, the call hangs and the whole engine fails to come up.
- In Cinnamon's `Eval`, `St` and `Clutter` are not globals: use `imports.gi.St`.
- Before picking a default shortcut, search everywhere: `gsettings list-recursively | grep -i "<Super>x"`. Super+O is the screen rotation lock (in `media-keys`).
- Super+Space is Cinnamon's keyboard layout switch; registering that shortcut overrides the system one.
- There is no `gjs` on the machine; the interpreter is `cjs`.
