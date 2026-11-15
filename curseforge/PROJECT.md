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

**Download badge.** The project ID is **1807559**. The top of the description shows the download count, `https://img.shields.io/curseforge/dt/1807559?logo=curseforge&label=downloads`. Until CurseForge's public API lists the project (after moderation), the badge reads "downloads: not found", and then shows the count.

The other badge service, the one CurseForge's support article on badges describes, is `https://cf.way2muchnoise.eu/full_1807559_downloads.svg`. It answered with a server error while the project wasn't listed, so it is only the fallback. CurseForge's rules allow functional badges at the top, as long as they are not promotional.

## Automatic packaging (set up once)

Files are packaged and uploaded by GitHub when a version tag is pushed: `.github/workflows/release.yml` runs the BigWigs packager, following `.pkgmeta`.

- **The zip** contains `Kong` and `KongConfig` at its root. `.pkgmeta` moves them there and leaves out the docs, `curseforge/` and `scripts/`. The `LICENSE` file goes inside `Kong`.
- **The project** comes from `## X-Curse-Project-ID: 1807559` in `Kong/Kong.toc`.
- **The game version** comes from `## Interface: 16001`, which the packager knows as Forever.
- **The changelog** of each file is that version's section of `CHANGELOG.md`, in Markdown. `scripts/release-notes.sh` extracts it into `RELEASE_NOTES.md` before packaging, so it shows on the website and in the CurseForge app. The workflow fails if the section is missing or lists nothing.
- **A missing token fails the run** with an error, instead of the packager silently skipping the upload.
- **The release type** comes from the tag: one containing `beta` or `alpha` makes a beta or alpha file, any other a release.

To set it up:

1. Create a CurseForge API token at <https://authors.curseforge.com/#/settings/api-tokens>.
2. On GitHub, open the repository's Settings > Secrets and variables > Actions > New repository secret. Name it `CF_API_TOKEN` and paste the token.
3. **Leave CurseForge's own "package on tagged commit" option off.** With both on, every tag would be uploaded twice.
4. **Dry run:** on GitHub, Actions > Package > Run workflow. When it finishes, download the "package" artifact and check that the zip holds exactly `Kong/` and `KongConfig/`. Nothing is uploaded.

## Releasing a version

1. Add a section at the top of `CHANGELOG.md`, for example `## 1.0.1 (2026-12-01)`, with `- ` entries under `### New`, `### Fixed` and `### Changed`: a player-facing summary of the new features and fixed bugs. Commit it.
2. Run `powershell -File scripts/release.ps1 -Version 1.0.1`. It checks that the working tree is clean and the changelog has the section, sets `## Version:` in both TOC files, commits, and tags.
3. Push `main` and the tag (Sourcetree: Push with "Push all tags" ticked, or add `-Push` to the command).
4. Follow the upload in GitHub's Actions tab, then check the new file on CurseForge: game version Forever 1.60.1, release type, changelog.

**First version:** nothing has been tested in-game yet, so publish it as a beta: `scripts/release.ps1 -Version 1.0.0-beta1` (it uses the `## 1.0.0` changelog section). Once it is confirmed, release `1.0.0`.

If an automatic upload fails, build the zip by hand with `powershell -File scripts/package.ps1` and upload `dist/KongUIHider-Forever-<version>.zip` on the project's Files page: game version Forever 1.60.1, changelog type Markdown.
