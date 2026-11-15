# Changelog

## 1.0.0 (2026-11-15)

First public release of Kong UI Hider - Forever, based on Kong Automatic UI Hider 1.6a by Xentaros.

- Runs on World of Warcraft: Forever (interface 16001).
- Handles the game values Forever hides from addons, such as exact health and mana, without errors.
- "Unit Health is Low" and "Unit Power is Low" work without exact health and mana: "not at full mana" now follows mana regeneration and the five-second rule.
- Chat fades as one: every chat window, tab, the dock and the chat buttons follow `ChatFrame1`, mouseover works over the chat text, and the typing bar fades with the chat.
- New conditions: "Message Received in Chat" and "Player is Typing in Chat".
- Details! windows fade as one window.
- Bartender4 bars can be selected in the settings window.
- Settings window: Copy Settings, Paste Settings and Reset Settings buttons. Unticking "Hide Selected Frame(s)" keeps the frame's settings.
- "Unit in Instance" is correct after logging in or reloading inside an instance.
- Saved frame paths are parsed instead of being run as code.
- Fixed an error at logout when a profile has no mouseover groups.
- New `/kong powerlog` diagnostic command.

See [FEATURES.md](FEATURES.md) for the full list.
