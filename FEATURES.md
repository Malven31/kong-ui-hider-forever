# Features

Kong UI Hider - Forever is the original **Kong Automatic UI Hider 1.6a** by Xentaros, ported to World of Warcraft: Forever. This page lists what the original does and what the port adds.

## From the original Kong 1.6a

### Fading

- Fades any frame of the interface in and out, whether it belongs to Blizzard or to another addon: action bars, unit frames, chat, minimap, damage meters, quest trackers.
- Each frame has its own list of **Show When** conditions. The frame is shown while at least one of them is true, and fades out when none is.
- **Mouseover always works.** Moving the cursor over a frame that Kong hides shows it ("Frame has Mouse Focus").
- A newly hidden frame starts with two conditions: mouseover, and "Unit in Combat" for the player.
- When several conditions are true at once, the one with the highest alpha wins, then the fastest fade.
- **Defaults per frame:** hidden alpha, shown alpha, fade-in time, fade-out time, and the delay before fading out (0%, 100%, 0.2 s, 1 s and 0 s unless you change them).
- **Per-condition settings:** each condition can override the shown alpha, the fade-in and fade-out times, and the fade-out delay (up to 60 seconds).
- **Mouseover groups:** put frames in a named group, and moving the cursor over any member shows them all.
- **Advanced options:**
  - "Dummy SetAlpha Function" stops other code from changing the frame's alpha.
  - "Hide At Zero Alpha" hides the frame completely once it has faded out.
  - "Save As" chooses the path Kong uses to find a nameless frame again at the next login.
- Fading pauses while the settings window is open, so you can see everything you configure.

### Settings window (`/kong`)

- Every frame on screen is covered by a clickable overlay. Click one to select it, shift-click to select several, and use the mouse wheel to reach the frames underneath.
- Tick **Hide Selected Frame(s)** to put the selection under Kong's control.
- **Add New Condition** opens the condition editor.
- On each condition, **Sync** gives it to every selected frame that doesn't have it yet, and **Delete** removes it.

### Conditions

Conditions are built from parts that combine with each other, for example "Unit Health (Percent) of Target, Less Than, 50".

- **Logic:** And, Or, Not, Equal, Not Equal, Less Than, Greater Than, True, False.
- **Numbers and text:** a number you type, a percentage, addition, subtraction, multiplication and division. Also text you type, "Text Contains Text" and "Combine Text", and conversion of text to a unit, a spell, a pet spell or a frame.
- **Units:**
  - Player, target, pet, mouseover, focus, the target of any unit.
  - Party and raid members and their pets.
  - Bosses, arena opponents and vehicles, as far as Forever has them.
- **Unit tests:**
  - Name, in combat, resting, casting, mounted, exists, "is the same unit as", moving, speed and speed percent.
  - Health, maximum health, health percent, "health is low".
  - Power, maximum power, power percent, "power is low", for mana, rage, energy, combo points and the other power types.
  - In range of a spell, in an instance (dungeon, raid, battleground, scenario, arena or any), dead, ghost, dead or ghost.
  - In a vehicle, interacting with an NPC.
- **Events:**
  - Seconds since an event, "event occurred recently", change in a value.
  - Chat message received, minimap ping, quest accepted, quest updated, player gained XP, player gained a level.
- **Other:** "Frame Is Visible", "Cursor Is Holding Something", and macro conditionals (the `[combat]`, `[mod:shift]`, `[@target,exists]` syntax of macros).

### Profiles, commands and key bindings

- Settings are saved per profile. By default each character gets its own profile, named after the character and its realm, and any character can load any profile.
- `/kong` opens the settings window.
- `/kong enable`, `/kong disable` and `/kong toggle` switch all fading on and off.
- `/kong profile list`, `current`, `create <name>`, `load <name>`, `delete <name>` and `reset` manage profiles.
- `/kong reset` resets the current profile, after a confirmation. `/kong help` lists the commands.
- Key bindings (Key Bindings > AddOns): enable fading, disable fading, toggle fading, and open the settings window.

## Added in the Forever port

### Runs on Forever

- Loads on Forever (interface 16001). Forever runs on the modern engine, so the conditions the original reserved for the retail game are offered as well.
- **Hidden game values are handled safely.** Forever hides some values from addons, such as the player's exact health and mana. Every condition checks for them before using them. A condition keeps its last readable value instead of raising an error, and a frame whose transparency is hidden counts as fully visible.
- Uses Forever's API where the original's calls no longer exist: spells and spell range, the cursor, mouse focus, loading the settings window, and greyed-out icons.
- The settings window runs on current copies of AceGUI-3.0 and CallbackHandler-1.0.
- The settings window skips frames that the game protects from addons, and one such frame no longer stops the others from getting an overlay. Before this, Bartender4's bars couldn't be selected at all.
- **"Unit Health is Low" works without exact health** (Forever hides it). The condition is true when the unit is dead or a ghost. For the player, it is also true while Blizzard's low-health warning shows (about 35% health or less). At 100%, "not at full health", it is also true for 3 seconds after each health change.
- **"Unit Power is Low" works without exact mana.** At 100%, "not at full mana", it is true while mana keeps changing (2.5 seconds after each change) and for 7.5 seconds after a spell that costs mana, which covers the five-second rule. So a frame shown "until mana is full" fades about 2.5 seconds after mana is full. Energy and focus work the same way. Values that the game doesn't hide still work exactly as in the original.
- "Unit in Instance" is correct right after logging in or reloading inside an instance.
- **Saved frame paths are read, never run.** The original turned the frame paths in its settings back into frames by running them as Lua code, so a modified settings file could run anything. The port reads them with a parser that only accepts frame names, table keys and `:GetParent()`.
- Logging out no longer raises an error when a profile has no mouseover groups.

### Chat

- **The whole chat fades as one.** Hide `ChatFrame1`, and every other chat window follows it, including whisper windows opened later, along with the tabs, the dock and the buttons beside the chat.
- Mouseover works over the text area of the chat. Before, only the tabs and buttons reacted.
- **The typing bar follows the chat's fade.** It is never touched while you type. A bar left open with text in it, after clicking away, fades with the chat instead of staying on screen.
- New condition **"Message Received in Chat"**: true for the number of seconds you choose after any chat window shows a new line. The combat log is ignored.
- New condition **"Player is Typing in Chat"**: true while a chat input box is open.

### Details!

- Details! windows fade as one window: the frame, the bars, and the click-catching layer over them. The bars are never more visible than their window, even when Details! resets them after a reload or a zone change.

### Settings window

- **Copy Settings / Paste Settings:** copies one frame's Show When conditions, defaults and advanced options to the selected frames. Mouseover groups are left alone.
- **Reset Settings:** discards the settings of the selected frames, after a confirmation.
- Unticking "Hide Selected Frame(s)" keeps the frame's settings, and ticking it again brings them back.

### Diagnostics

- `/kong powerlog` records 90 seconds of mana events, casts and "Unit Power is Low" changes into the saved variables, to help tune the mana conditions. Type `/reload` afterwards to write it to disk.
