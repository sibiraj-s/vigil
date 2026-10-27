# Vigil

[![CI](https://github.com/sibiraj-s/vigil/actions/workflows/ci.yml/badge.svg)](https://github.com/sibiraj-s/vigil/actions/workflows/ci.yml)

Keeps your Mac awake for as long as you need. A menu bar app for macOS, built with SwiftUI.

## Features

- Sessions from the menu bar: indefinitely, for 15 minutes to 5 hours, until a time of day, while an app runs, or while a download finishes
- A countdown next to the menu bar icon for timed sessions
- Triggers that keep the Mac awake on their own while a condition holds: chosen apps are running, an external display or drive is connected, the Mac is plugged in or on battery, it's on a given Wi‑Fi network, or it's within a weekly schedule
- Global keyboard shortcuts to start or end a session from any app (⌥⌘0 for indefinitely and ⌥⌘1 for an hour by default), set up in Settings → Shortcuts
- A battery guard that ends sessions when the battery drops below a level you choose while unplugged
- Optionally lets the display sleep while the Mac itself stays awake
- Opens at login if you want it to

## Install

Requires macOS 27 or later on Apple Silicon.

1. Download `Vigil-<version>.dmg` from the [latest release](https://github.com/sibiraj-s/vigil/releases/latest).
2. Open it and drag Vigil to Applications.

Vigil checks for updates once a day and installs them from within the app.

Wi‑Fi triggers need Location Services: macOS only shares the network name with apps that have location access.

## License

[MIT](./LICENSE)
