# Kong UI Hider - Forever

Fade any part of your interface in and out on the conditions you choose: mouseover, combat, a new chat message, low health, mana regenerating, and many more. Your screen stays clear until you need something.

This is the original **Kong Automatic UI Hider 1.6a** by Xentaros, ported to **World of Warcraft: Forever**.

- [Features](FEATURES.md): everything the original does and what the port adds.
- [Changelog](CHANGELOG.md)

## Install

Install it from CurseForge (Forever flavor), or by hand:

1. Copy the `Kong` and `KongConfig` folders into `World of Warcraft\_forever_\Interface\AddOns`.
2. Restart the game.

Both folders are needed. `Kong` does the fading. `KongConfig` is the settings window, and it only loads when you open it.

Upgrading from an earlier Kong build for Forever? Replace the two folders. The folder and saved-variable names are the same, so your settings and profiles carry over.

## Quick start

1. Type `/kong`. Fading pauses, and every frame on screen gets a clickable overlay.
2. Click the frame you want to hide. Shift-click to select several, and use the mouse wheel to reach the frames underneath.
3. Tick **Hide Selected Frame(s)**. The frame now shows on mouseover and in combat, and fades the rest of the time.
4. Under **Show When**, add or change conditions. For example: show the chat for 15 seconds after a new message, or keep the player frame up until your mana is full.
5. Close the window, and fading resumes.

## Commands

| Command | What it does |
|---|---|
| `/kong` | Opens the settings window |
| `/kong enable`, `/kong disable`, `/kong toggle` | Switches all fading on or off |
| `/kong profile list`, `current`, `create <name>`, `load <name>`, `delete <name>`, `reset` | Manages profiles |
| `/kong reset` | Resets the current profile, after a confirmation |
| `/kong powerlog` | Records 90 seconds of mana events into the saved variables, for troubleshooting |
| `/kong help` | Lists the commands |

Key bindings for enabling, disabling and toggling fading, and for opening the settings window, are under Key Bindings > AddOns.

## Good to know on Forever

- **Exact health and mana are hidden from addons on Forever.** "Unit Health is Low" and "Unit Power is Low" use the signals the game still gives, as described in [FEATURES.md](FEATURES.md). Comparing "Unit Health" or "Unit Power" to a number yourself doesn't work, because they read as 0 while hidden.
- **"Not at full mana" ends a little late.** Nothing tells an addon the moment mana is full, so a frame shown until mana is full fades about 2.5 seconds after it fills.
- **"Dummy SetAlpha Function"** replaces the frame's own transparency function. Use it only when another addon keeps resetting a frame's transparency. On Blizzard frames it can cause "Interface action failed because of an AddOn" errors.
- **"Hide At Zero Alpha"**: the game doesn't let addons hide action bars and unit frames during combat, so leave it off for those.

## Credits

- Original addon: **Kong Automatic UI Hider 1.6a** by Xentaros, released into the public domain.
- Forever port: **Malven31**, made with Claude (Anthropic).
- Bundled libraries: AceGUI-3.0 and CallbackHandler-1.0 by the Ace3 Development Team (BSD-style licence), and LibStub (public domain).

## Licence

Public domain, see [LICENSE](LICENSE). The bundled Ace3 libraries keep their own licence. Their `LICENSE.txt` files are in `KongConfig/libs`.

## Building a release zip

```powershell
powershell -File scripts/package.ps1
```

This writes `dist/KongUIHider-Forever-<version>.zip`, with `Kong` and `KongConfig` at the root of the archive, ready to upload. The version comes from `Kong/Kong.toc`.
