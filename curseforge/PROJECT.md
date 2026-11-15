# CurseForge checklist

Everything the CurseForge project and file upload ask for, ready to paste.

## Before the first upload

1. **Test in the game** with a fresh `/reload` and a logout, and check the BugSack for errors:
   - Frames you already hide come back faded after `/reload`. This checks the new frame-path parser.
   - The chat fades, shows on mouseover over its text, and the typing bar follows it.
   - Bartender4 bars can be selected in `/kong`.
   - Details! windows fade as one.
   - Copy, Paste and Reset Settings work.
   - The player frame stays up while mana regenerates and fades about 2.5 seconds after it is full.
   - The minimap button opens and closes the settings, right-click turns fading on and off, dragging moves it, and the position survives `/reload`. `/kong minimap` hides and shows it.
   - Logging out raises no error.
2. **Repository:** `github.com/Malven31/kong-ui-hider-forever` (renamed from `king-kong-frame-fader-forever`; GitHub redirects the old address).
3. **Visibility:** the Source and Issues links below only work if the repository is public.
4. **Logo:** [logo.png](logo.png) (256×256, the port's own). The minimap icon `Kong/media/minimap.tga` is the same design.
5. **Screenshots:** see [gallery/README.md](gallery/README.md).

## Moderation rules to keep in mind

From CurseForge's moderation policies (<https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies>):

- The name, logo, summary and description are the port's own. Nothing is copied from the original's page.
- The original creator is credited and linked, in the description's Credits section. Its licence (Public Domain) allows the port.
- Outside links, such as the GitHub repository and any donation link, go at the very bottom of the description, small.
- Keep a channel for bug reports open: the project's comments, plus GitHub Issues once the repository is public.
- If CurseForge asks for changes or rejects the project, fix it and reply or appeal. Never delete the project or file to upload it again.

## Create the project

| Field | Value |
|---|---|
| Game | World of Warcraft |
| Project type | Addons |
| Name | Kong UI Hider - Forever |
| Summary | Fades any interface frame in and out on mouseover, combat, chat and more. Kong, ported to Forever. |
| Description | [description.md](description.md) |
| Category | Miscellaneous, as the original Kong used. Add the closest interface categories CurseForge offers if you like (for example HUDs, Action Bars, Chat & Communication). |
| Licence | Public Domain |
| Logo | [logo.png](logo.png) |
| Source | `https://github.com/Malven31/kong-ui-hider-forever` (after the rename, if public) |
| Issues | `https://github.com/Malven31/kong-ui-hider-forever/issues` (same condition) |

If the description editor has no Markdown mode, open `description.md` in a Markdown preview (VS Code: Ctrl+Shift+V) and copy the rendered text. The formatting comes along.

## Upload a file

| Field | Value |
|---|---|
| File | `dist/KongUIHider-Forever-1.0.0.zip`, built by `powershell -File scripts/package.ps1` |
| Display name | Kong UI Hider - Forever 1.0.0 |
| Release type | Beta for the first upload, until the checks above are done; Release after |
| Game version | Forever, 1.60.1 (the current Forever client) |
| Changelog | The section for this version from [CHANGELOG.md](../CHANGELOG.md), with the changelog type set to Markdown |

## For each new version

1. Raise `## Version:` in both `Kong/Kong.toc` and `KongConfig/KongConfig.toc`.
2. Add a section at the top of `CHANGELOG.md`.
3. Run `scripts/package.ps1` and upload the new zip with that changelog section.
4. Tick the newest Forever game version on the upload form.
