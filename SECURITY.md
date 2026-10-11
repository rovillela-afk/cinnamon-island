# Privacy and security

## What the app reaches on the internet

Cinnamon Island has no account, collects no usage data and never talks to a server run by the author. These are its only connections:

| Where | When | What is sent |
| --- | --- | --- |
| Open-Meteo (`open-meteo.com`) | Weather tab: when searching for a city and every 30 minutes | The text typed in the search and the coordinates of the chosen cities |
| The address of your calendar | Agenda tab, every 15 minutes, if you provided an iCal link | Only the request for the file |
| LRCLIB (`lrclib.net`) | Media tab, only after you turn lyrics on | Title, artist, album and length of the song. Never for what plays in browsers |
| The address of the album cover | When the player reports the cover as a link | Only the request for the image |

Every download has a timeout and a size cap, and only `http` and `https` addresses are accepted.

## What stays on your computer

| What | Where | Note |
| --- | --- | --- |
| Notes | `~/.local/share/cinnamon-island/notes.txt` | Readable by the owner only |
| Pomodoro statistics and session, shelf list, last song | `~/.local/share/cinnamon-island/` | The shelf stores only file paths |
| Cities and calendar link | `~/.config/cinnamon-island/weather.json` | Readable by the owner only |
| Extension settings | `~/.config/cinnamon/spices/cinnamon-island@rovillela/` | Includes the calendar link |
| Covers and lyrics | `~/.cache/cinnamon-island/` | Safe to delete at any time |

These exist in memory only and are gone when the engine stops: the clipboard history, the notification inbox and the sound measured for the wave bars.

## Things to be aware of

- **Calendar link.** The "secret address in iCal format" grants read access to all your events. It is stored as plain text in your home folder and is included when you export the extension settings. Do not share that file without clearing the field. Prefer an `https` link.
- **Clipboard.** The history skips what comes from password managers that tag their content as sensitive (`x-kde-passwordManagerHint`, used by KeePassXC and others). A password copied from a program that does not tag it enters the history until you clear it or the engine restarts. The tab can be turned off in the settings.
- **Notifications.** The option is off by default. With it on, notification titles show on the island, at the top of the screen, and the text stays in the tab until you dismiss it. Turn the option off if you often share your screen.
- **Wave bars.** To follow the sound, the engine measures what goes out to the speakers or headphones (not the microphone). Nothing is written to disk or sent anywhere.
- **Camera.** It only turns on when you click the Camera button, shows the picture in a window and turns itself off after 5 minutes. Nothing is recorded.
- **D-Bus.** The engine answers any program running in your session, as your user. Such a program can already read your files and your clipboard, so the engine adds no access; but it is not a barrier against malicious programs you run yourself.

## How the code protects itself

- No command is ever built as text for a shell: external programs (`pactl`, `tesseract`, `gnome-screenshot`…) are called with an argument list.
- The engine uses no third-party libraries besides PyGObject, which comes from the system.
- Nothing is installed with privileges: the .deb has no scripts, and the engine runs as a user service, never as root.
- Temporary files live in a folder created for the user only.

## Reporting a vulnerability

If you found a security problem, please do not open a public issue. Use "Report a vulnerability" in the Security tab of the repository on GitHub, which is a private channel with the author. For ordinary bugs, an issue is fine.

Only the latest version receives fixes.
