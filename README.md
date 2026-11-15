# Kong UI Hider - Forever

[![CurseForge downloads](https://img.shields.io/curseforge/dt/1807559?logo=curseforge&label=downloads)](https://www.curseforge.com/wow/addons/kong-ui-hider-forever)

Fade any part of your interface in and out on the conditions you choose: mouseover, combat, a new chat message, low health, mana regenerating, and many more. Your screen stays clear until you need something.

This is the original **Kong Automatic UI Hider 1.6a** by Xentaros, ported to **World of Warcraft: Forever**.

![The chat and the damage meters fading in on mouseover, then out again](curseforge/gallery/kong_fader_ui.gif)

- [Features](FEATURES.md): everything the original does and what the port adds.
- [Changelog](CHANGELOG.md)

## Install

Install it from [CurseForge](https://www.curseforge.com/wow/addons/kong-ui-hider-forever) (Forever flavor), or by hand:

1. Copy the `Kong` and `KongConfig` folders into `World of Warcraft\_forever_\Interface\AddOns`.
2. Restart the game.

Both folders are needed. `Kong` does the fading. `KongConfig` is the settings window, and it only loads when you open it.

Upgrading from an earlier Kong build for Forever? Replace the two folders. The folder and saved-variable names are the same, so your settings and profiles carry over.

## Quick start

1. Type `/kong`, or left-click the minimap button. Fading pauses, and every frame on screen gets a clickable overlay.
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
| `/kong minimap` | Hides or shows the minimap button |
| `/kong powerlog` | Records 90 seconds of mana events into the saved variables, for troubleshooting |
| `/kong help` | Lists the commands |

Key bindings for enabling, disabling and toggling fading, and for opening the settings window, are under Key Bindings > AddOns.

The **minimap button** opens or closes the settings window with a left-click, and turns fading on or off with a right-click. Drag it to move it around the minimap. Its position is saved for all your characters.

## Good to know on Forever

- **Exact health and mana are hidden from addons on Forever.** "Unit Health is Low" and "Unit Power is Low" use the signals the game still gives, as described in [FEATURES.md](FEATURES.md). Comparing "Unit Health" or "Unit Power" to a number yourself doesn't work, because they read as 0 while hidden.
- **"Not at full mana" ends a little late.** Nothing tells an addon the moment mana is full, so a frame shown until mana is full fades about 2.5 seconds after it fills.
- **"Dummy SetAlpha Function"** replaces the frame's own transparency function. Use it only when another addon keeps resetting a frame's transparency. On Blizzard frames it can cause "Interface action failed because of an AddOn" errors.
- **"Hide At Zero Alpha"**: the game doesn't let addons hide action bars and unit frames during combat, so leave it off for those.

## Credits

- Original addon: **[Kong Automatic UI Hider](https://www.curseforge.com/wow/addons/kong) 1.6a** by Xentaros, released into the public domain.
- Forever port: **Malven31**, made with Claude (Anthropic). The logo is the port's own.
- Bundled libraries: AceGUI-3.0 and CallbackHandler-1.0 by the Ace3 Development Team (BSD-style licence), and LibStub (public domain).

## Licence

Public domain, see [LICENSE](LICENSE). The bundled Ace3 libraries keep their own licence. Their `LICENSE.txt` files are in `KongConfig/libs`.

## Releasing

Releases are packaged and uploaded to CurseForge automatically when a version tag is pushed. The GitHub workflow `.github/workflows/release.yml` runs the [BigWigs packager](https://github.com/BigWigsMods/packager), following `.pkgmeta`.

1. Add a section for the new version at the top of `CHANGELOG.md`, for example `## 1.0.1 (2026-12-01)`, summarising for players what is new (`### New`), fixed (`### Fixed`) and changed (`### Changed`). Commit it. This section, and only this one, becomes the changelog of the file on CurseForge (website and app). A release without it is refused.
2. Run `powershell -File scripts/release.ps1 -Version 1.0.1`. It sets the version in both TOC files, commits, and tags.
3. Push the branch and the tag, or add `-Push` to the command.

A tag containing `beta` or `alpha` (for example `1.1.0-beta1`) becomes a beta or alpha file on CurseForge, and any other tag a release. To check a build without publishing it, run the workflow by hand from the Actions tab: it attaches the zip to the run instead of uploading it.

To build a zip locally instead, run `powershell -File scripts/package.ps1`. It writes `dist/KongUIHider-Forever-<version>.zip`, with `Kong` and `KongConfig` at the root of the archive.
