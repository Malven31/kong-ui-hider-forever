# Kong UI Hider - Forever

<!-- Download badge: replace PROJECT_ID with the number shown under "About Project" on the CurseForge page, once the project exists. The badge is served by cf.way2muchnoise.eu, the service CurseForge's support article on badges describes. -->
![Downloads](https://cf.way2muchnoise.eu/full_PROJECT_ID_downloads.svg)

**Fade any part of your interface in and out on the conditions you choose.** Action bars that appear on mouseover or in combat. A chat that shows up when a message arrives and hides again after. A player frame that stays until your mana is full. Your screen stays clear until you need something.

This is the classic **Kong Automatic UI Hider 1.6a** by Xentaros, ported to **World of Warcraft: Forever**, with fixes and additions for Forever's client.

## What it does

- **Fades any frame:** Blizzard's or another addon's, such as action bars, unit frames, chat, minimap, Details! windows and quest trackers.
- **Shows frames when you need them:** mouseover always works. Add conditions such as "in combat", "has a target", "in an instance", "mana not full", "chat message in the last 15 seconds", "typing in chat", or any macro condition (`[combat]`, `[mod:shift]`, `[@target,exists]`...).
- **Combines conditions** with And, Or, Not and comparisons, on units, health, power, events, text and numbers.
- **Per-frame settings:** hidden and shown transparency, fade-in and fade-out times, and the delay before fading out. Each condition can override them.
- **Mouseover groups:** hover one bar and the whole group shows.
- **Point and click setup:** type `/kong` or click the minimap button, click a frame on screen, tick "Hide Selected Frame(s)", done.
- **Profiles** per character or shared, and key bindings to switch fading on and off.

## New in the Forever port

- Runs on Forever without errors, including the values Forever hides from addons (exact health and mana).
- **"Not at full mana" and "health is low" work again**, using regeneration and Blizzard's low-health warning.
- **The whole chat fades as one:** every chat window, tab and button, whisper windows included. Mouseover works over the chat text, and the typing bar follows the fade.
- New conditions: **Message Received in Chat** and **Player is Typing in Chat**.
- **Details! windows** fade as one window.
- **Bartender4 bars** can be selected.
- **Copy, Paste and Reset Settings** buttons in the settings window.
- **Minimap button:** left-click opens the settings, right-click turns fading on or off, drag it to move it. `/kong minimap` hides it.
- Saved settings are read safely: frame paths are parsed, never run as code.

The full list is in FEATURES.md in the source repository.

## Quick start

1. Type `/kong`, or left-click the minimap button.
2. Click the frame you want to hide (shift-click for several; the mouse wheel reaches frames underneath).
3. Tick **Hide Selected Frame(s)**, then add conditions under **Show When**.
4. Close the window.

## Good to know

- Exact health and mana are hidden from addons on Forever, so the health and mana conditions use the signals the game still gives. A frame shown "until mana is full" fades about 2.5 seconds after it fills.
- Leave "Hide At Zero Alpha" off for action bars and unit frames. The game doesn't let addons hide those during combat.
- Upgrading from an earlier Kong build for Forever keeps your settings.

## Credits

- Original addon: **[Kong Automatic UI Hider](https://www.curseforge.com/wow/addons/kong) 1.6a** by Xentaros, released into the public domain.
- Forever port: **Malven31**, made with Claude (Anthropic).
- Libraries: AceGUI-3.0 and CallbackHandler-1.0 (Ace3 Development Team), LibStub.

Licence: public domain. The bundled Ace3 libraries keep their own BSD-style licence.

## Feedback

Report bugs and suggest features in the comments on this page.

<!-- Once the GitHub repository is public, add here, at the bottom of the page as CurseForge requires:
Source code and issue tracker: https://github.com/Malven31/kong-ui-hider-forever -->
