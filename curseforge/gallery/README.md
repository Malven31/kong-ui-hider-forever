# Gallery

Screenshots for the CurseForge gallery go in this folder.

`kong_fader_ui.gif` is the animation shown under the introduction of the CurseForge description and of the repository README. The description loads it from `https://raw.githubusercontent.com/Malven31/kong-ui-hider-forever/main/curseforge/gallery/kong_fader_ui.gif`, so keep the file name and keep the repository public. It was reduced from 59.7 MB to 9.6 MB without changing its size or frame rate: `magick original.gif -fuzz 4% -layers Optimize kong_fader_ui.gif` (ImageMagick) after an `ffmpeg` palette pass.

`private/` is ignored by git. It keeps the originals that don't belong in the repository: captures too large to commit, and screenshots showing a character name. CurseForge shows each image with a title and a description, so each shot below has both ready to paste.

Tips:

- Use PNG or JPG. Take them with the in-game screenshot key (Print Screen). They are saved in `_forever_\Screenshots`.
- Hide the names of other players and your own character if you prefer, and keep chat free of private messages.
- The same spot and camera angle for the "before" and "after" shots makes the difference obvious.

| File | What to show | Title | Description |
|---|---|---|---|
| `01-before.png` | Your usual interface, everything visible | Before | The interface with every frame shown. |
| `02-after.png` | The same spot with Kong fading: bars, chat and frames hidden | After | The same view with Kong UI Hider: only what you need stays on screen. |
| `03-mouseover.png` | The cursor over a faded action bar, the bar (or its whole mouseover group) visible | Mouseover | Hidden frames come back as soon as the cursor reaches them, and mouseover groups bring back a whole set at once. |
| `04-config.png` | The `/kong` window open with the frame overlays, one frame selected | Point and click setup | Type /kong, click a frame on screen and tick "Hide Selected Frame(s)". |
| `05-conditions.png` | A frame's Show When list with a few conditions expanded (for example "in combat" and "chat message within the last 15 seconds") | Show When conditions | Combine conditions on combat, units, health, mana, chat, events and macro conditions. |
| `06-chat.png` | The chat shown right after a message arrives, the rest of the interface faded | Chat that comes back when you need it | Every chat window, tab and button fades as one, and comes back on mouseover, on new messages or while you type. |
| `07-mana.png` | The player frame visible while mana regenerates after a cast | Until your mana is full | Keep the player frame up while mana regenerates, and let it fade once mana is full. |
| `08-minimap.png` | The minimap with the button and its tooltip | Minimap button | Left-click opens the settings, right-click turns fading on or off. |
| `09-details.png` (if you use Details!) | A Details! window faded, then shown on mouseover | Details! support | Details! windows fade as one window, bars included. |

Rename or drop shots freely.
