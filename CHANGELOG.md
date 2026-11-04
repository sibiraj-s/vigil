# vigil

## 1.0.4

### Patch Changes

- e4d9748: Vigil now applies changed settings in one place, so a setting changed anywhere, such as triggers, shortcuts, appearance or the battery guard, always takes effect right away
- be67f6a: Switching between keeping the display on and letting it sleep no longer leaves a moment where nothing holds the Mac awake
- 6418eeb: While the battery guard is holding, the menu's session options are disabled and keyboard shortcuts beep, instead of silently doing nothing
- 84fb797: Checking triggers does less work: each source, such as mounted drives or running apps, is read once per check instead of once per trigger
- 1e187a0: Overnight schedules now keep the Mac awake after midnight on the day they started, and a failed "Open at login" change now shows its error instead of losing it
- 5ec8193: A schedule can no longer be saved with the same start and end time, which made a trigger that never fired
- 90d8cce: The Battery guard switch in the Triggers and Battery & Power settings is now one shared control, so both always read and behave the same
- b6abe22: Recording a shortcut saves your settings once instead of three times
- 1064cfd: Paused triggers stay paused through brief dropouts, such as Wi‑Fi roaming or a display waking; a pause now clears only after the trigger's condition has been off for 30 seconds

## 1.0.3

### Patch Changes

- 12ae3d6: Smaller downloads: The DMG now uses stronger compression, making the download about a third smaller

## 1.0.2

### Patch Changes

- 35b0cae: Ending a session now stops only the manual session and leaves active triggers keeping the Mac awake. Press End session again to pause triggers, and use Resume trigger to turn them back on. To have End session stop triggers too, choose "Session and triggers" under Settings → General → End session stops.
- 23fd4d3: Opening Settings from the menu now closes the menu and brings the Settings window to the front, instead of sometimes leaving it behind other apps.
- 0b452af: Check for Updates… now closes the menu.

## 1.0.1

### Patch Changes

- 003f746: Add "Check for updates automatically" setting in Settings → General.

## 1.0.0

### Major Changes

- 4096434: First release.

### Patch Changes

- fe500a4: Fix app crash when removing a shortcut
- 7a674d4: Add missing app icon
