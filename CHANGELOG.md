# Changelog

Each version has a section `## <version> (<date>)` summarising, for players, what is new (`### New`), fixed (`### Fixed`) and changed (`### Changed`). That section, and only that section, is sent to CurseForge as the changelog of the version's file, so it shows on the website and in the CurseForge app. A beta (`1.1.0-beta1`) uses its own section if it has one, otherwise the section of its final version (`1.1.0`). The full feature list is in FEATURES.md.

## 1.0.0 (2026-11-16)

First public release of Kong UI Hider - Forever, based on Kong Automatic UI Hider 1.6a by Xentaros.

### New

- Runs on World of Warcraft: Forever (interface 16001).
- Handles the game values Forever hides from addons, such as exact health and mana, without errors.
- "Unit Health is Low" and "Unit Power is Low" work without exact health and mana: "not at full mana" follows mana regeneration and the five-second rule.
- Chat fades as one: every chat window, tab, the dock and the chat buttons follow the main chat window, mouseover works over the chat text, and the typing bar fades with the chat.
- New conditions: "Message Received in Chat" and "Player is Typing in Chat".
- Details! windows fade as one window.
- Bartender4 bars can be selected in the settings window.
- Settings window: Copy Settings, Paste Settings and Reset Settings buttons. Unticking "Hide Selected Frame(s)" keeps the frame's settings.
- Minimap button: left-click opens the settings, right-click turns fading on or off, drag to move it. `/kong minimap` hides it.
- `/kong powerlog` diagnostic command for the mana conditions.

### Fixed

- "Unit in Instance" is correct right after logging in or reloading inside an instance.
- No more error at logout when a profile has no mouseover groups.

### Changed

- Saved frame paths are read by a parser instead of being run as code, so a modified settings file can no longer run anything.
