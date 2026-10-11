# Cinnamon Island: plan and decisions

This document says what the app is, what is already done, why each choice was made and what may come next. The step-by-step of how each part was built is in the Git history; the rules for working on the code are in [CLAUDE.md](CLAUDE.md).

## What it is

A translucent glass notch against the screen edge that expands into tabs: sound, media, clock, agenda, notes, clipboard, files, weather, notifications, system and tools. It is the idea of the Mac notch apps (NotchNook, Alcove, The Boring Notch, Vorssaint), built for Cinnamon and designed for desktop PCs, with no physical notch needed.

- **Where it runs:** Linux Mint or another distribution with Cinnamon 6.x, in an X11 session.
- **Name:** Cinnamon Island. "LinuxNotch" was dropped because the app only runs on Cinnamon.
- **License:** GPL-3.0-or-later, the same as Cinnamon.
- **Language:** code, comments and documents are in English. The interface is English in the code, with a Brazilian Portuguese translation; it follows the system language and falls back to English.

## How it is built

The app has two halves that talk over D-Bus:

- **Engine** (`engine/`, Python with PyGObject, no other dependencies): does all the work. Each tab is an interface at `org.cinnamonisland.Engine`, with `GetState()` (JSON), the `StateChanged` signal and its commands.
- **Extension** (`extension/`, JavaScript): only draws. It is a Cinnamon extension because only from inside Cinnamon is there real blur behind the glass.

The split exists so another desktop (GNOME, KDE) can get its own front end on top of the same engine. Today only the Cinnamon front end exists.

The engine is a user service (`cinnamon-island-engine.service`) when installed from the .deb or with `install.sh`, and ships inside the extension when it is installed from the .zip or the store. In both cases the extension is what starts it.

## What is done

### The island

- Sits on the primary monitor, at the top (default), bottom or sides.
- Opens on hover (with an adjustable delay) or only on click; closes when the mouse leaves. Super+I opens and pins it, and in that mode the keyboard navigates: arrows and Tab switch tabs, numbers go straight to a tab, Esc closes.
- A pin keeps the island open with the mouse away; a gear opens the settings.
- Tabs are orbs on both sides of the island. The mouse wheel switches tabs anywhere, except over a control that uses it (bars, rulers, lists).
- It can stay hidden, coming back when the mouse touches the edge or when there is a notice.
- It always opens on the last tab used.

### The closed island

Depending on what is going on, it shows: the cover and wave bars of the music (the bars follow the real sound), the time of the timer, the Pomodoro or the stopwatch, the countdown to the next event, the "keep awake" time and a bar when the volume changes. It also shows notices for a few seconds: download finished, microphone on or muted, Bluetooth accessory connected or low on battery, link cleaned, system notification.

### The tabs

| Tab | What it does | Where the data comes from |
| --- | --- | --- |
| Volume | A mixer: audio outputs, master volume, microphone and one bar per program playing sound (up to 150%) | `pactl` (PipeWire or PulseAudio) |
| Media | Controls what plays, picks between players, program volume, synced lyrics, "up next" queue, resume the last Spotify song | MPRIS; LRCLIB for lyrics |
| Clock | Pomodoro (with task and statistics), timer and stopwatch, with a minute ruler | Engine only |
| Agenda | The month, with the days that have events, and the upcoming events | An iCal link provided by the person |
| Notes | A block of text that saves itself; copy everything or send it to the shelf | Local file |
| Clipboard | History of what was copied; strips trackers from links | Clipboard |
| Files | Drag-and-drop shelf; stores only the path of the files | Invisible engine window |
| Weather | Forecast for up to five cities | Open-Meteo |
| Notifications (off by default) | Inbox of the system notifications | Listening on D-Bus |
| System | CPU, memory, graphics card, disks, network and battery, with graphs | `/proc`, `/sys`, `nvidia-smi` |
| Tools | Keep the screen awake, colour picker, screenshots, copy text from the screen (OCR), camera mirror | Session inhibitor, `gnome-screenshot`, `tesseract`, GStreamer |

### Settings, language and packages

- Settings use Cinnamon's own window, in pages (General, Tabs, Pomodoro, Agenda, Notices). The order of the tabs and which ones show are adjustable; Volume always shows.
- English and Brazilian Portuguese. Texts are English in the code and the translation lives in `po/pt_BR.po`.
- `./package.sh` builds the extension .zip with the engine inside, the folder in the Cinnamon store layout and the .deb.

## Decisions and their reasons

| Decision | Reason |
| --- | --- |
| A Cinnamon extension, not a separate program | Cinnamon only blurs the background of its own components |
| Logic in the engine, drawing in the extension | Cinnamon extensions are JavaScript; a Python engine can serve other desktops later |
| X11 only | Cinnamon's Wayland is still experimental, and the shelf depends on X11 |
| Agenda through an iCal link, no Google login | No need to register an app with Google or store a token |
| Shelf backed by an invisible engine window | Extensions do not receive drag and drop from other programs |
| Files stay on the shelf until removed | Disappearing on open or drag was confusing |
| Notifications by listening, without replacing Cinnamon's service | Breaks nothing in the desktop; the cost is Cinnamon's own banner showing as well |
| Notifications off by default | The tab duplicates what Cinnamon already shows and puts notification text at the top of the screen; whoever wants it turns it on in the settings |
| Clipboard history and notifications in memory only | Nothing sensitive goes to disk |
| Lyrics only after the person turns them on | The lookup sends title and artist to an outside service |
| Colour only in details, four tones | The island is dark glass; colour everywhere was tiring. Blue is sound, green is microphone and "active", yellow is application and time, rose is mute and alert |
| No font of its own: the island uses the font of the Cinnamon theme | The Cinnamon store takes no binary files, and the .deb, the .zip and the store version are meant to be identical |
| No separate video tab | The Media tab already controls any player, video included |

Left out on purpose: a mascot, a lock screen, watching a region of a window, and the Spotify queue (Spotify does not report it).

## Known limits

- **Glass:** the concave curves of the notch have no blur (Cinnamon only blurs outward corners). With the panel at the top, the island covers its centre.
- **Media:** Firefox does not report length or position for YouTube videos; the progress bar goes away in those cases. The "up next" queue depends on the player reporting it and has not been seen working.
- **Agenda:** recurring events need `python3-dateutil`.
- **Weather:** the search does not understand postal codes.
- **Notifications:** those Cinnamon creates internally do not show up. Clicking one in the inbox does what clicking Cinnamon's banner would while Cinnamon still holds the notification; later it can only bring the program's window forward (or start the program). The extra action buttons of a notification ("Reply", "Mark as read") are not offered. A notification whose program cannot be identified stays in the list with a message.
- **System:** Intel graphics have no usage reading. For a disk with no mounted partition only the size is known.
- **Engine restart:** the Pomodoro is resumed; the timer, the stopwatch, the clipboard history and the notification inbox are lost.
- **Sides:** with the island on the left or right, the closed island does not show cover, wave bars or volume bar.

Little or no testing, for lack of hardware on the development machine: Bluetooth and accessory battery notices, the battery card, AMD graphics, USB disks.

## What may come next

- Publish to the Cinnamon store (Cinnamon Spices). The folder `package.sh` builds passes the store's automatic checks, and the code follows its review guide (gettext, no blocking I/O, no binary files), so the store version is the same as the one on GitHub. The author has chosen not to submit for now: the store asks authors to review AI-assisted code themselves.
- A front end for GNOME. It is a project of its own: blur is done differently and GNOME defaults to Wayland. KDE and Hyprland would need the front end rewritten from scratch.
- Wayland support, once Cinnamon's matures.
- Keep the timer and the stopwatch across engine restarts.
- More interface languages (add a `po/<language>.po` file).
- Following AI agents on the island (undecided).
- Flatpak or packages for other distributions.

## References

- Mac: [NotchNook](https://lo.cafe/notchnook), Alcove, [The Boring Notch](https://github.com/TheBoredTeam/boring.notch), [Vorssaint](https://vorssaint.com/) (the ideas, not the code or the identity).
- Linux: [Dynamic Glacier](https://github.com/amanhex/DynamicGlacierV2) (Hyprland), [dynamic-island](https://github.com/thanvish21/dynamic-island) (Tauri).
