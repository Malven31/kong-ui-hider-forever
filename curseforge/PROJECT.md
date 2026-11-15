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
   - Logging out raises no error.
2. **Repository name:** rename `king-kong-frame-fader-forever` to `kong-ui-hider-forever` on GitHub (Settings > General > Repository name). GitHub redirects the old address.
3. **Visibility:** the Source and Issues links below only work if the repository is public.
4. **Logo:** CurseForge asks for a square project logo. Make one before creating the project.
5. **Screenshots:** see [gallery/README.md](gallery/README.md).

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
