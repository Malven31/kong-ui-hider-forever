local LibUSC = LibStub and LibStub("LibUserSpecifiedConditions", true)
if not LibUSC then return end

local CATEGORY = nil

-- Forever port: Forever (interface 16001) runs the Mainline engine, including secret values.
local issecretvalue = issecretvalue or function() return false end
local IS_MAINLINE_FAMILY = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
    or (WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)

LibUSC:RegisterParameter("Mana", { 
    version = 2,
    type = "Power",
    category = CATEGORY,
    description = "Power type used by most casters",
    value = 0,
})
LibUSC:SetTypeDefault("Power", "Mana")

LibUSC:RegisterParameter("Rage", { 
    version = 2,
    type = "Power",
    category = CATEGORY,
    description = "Power type used by warriors and druids in bear form",
    value = 1,
})

LibUSC:RegisterParameter("Energy", { 
    version = 2,
    type = "Power",
    category = CATEGORY,
    description = "Power type used by rogues and druids in cat form",
    value = 3,
})

LibUSC:RegisterParameter("Combo Points", { 
    version = 2,
    type = "Power",
    category = CATEGORY,
    description = "Power type used by rogues and druids in cat form",
    value = 4,
})

LibUSC:RegisterParameter("Dungeon", { 
    version = 2,
    type = "Instance",
    category = CATEGORY,
    description = "A five player PvE instance",
    value = "party",
})
LibUSC:SetTypeDefault("Instance", "Dungeon")

LibUSC:RegisterParameter("Raid", { 
    version = 2,
    type = "Instance",
    category = CATEGORY,
    description = "A 10+ player PvE instance",
    value = "raid",
})

LibUSC:RegisterParameter("Battleground", { 
    version = 2,
    type = "Instance",
    category = CATEGORY,
    description = "A 10+ player PvP instance",
    value = "pvp",
})

LibUSC:RegisterParameter("Scenario", { 
    version = 2,
    type = "Instance",
    category = CATEGORY,
    description = "A short PvE instance such as Delves",
    value = "scenario",
})

LibUSC:RegisterParameter("Any", { 
    version = 2,
    type = "Instance",
    category = CATEGORY,
    description = "Any instance",
    value = "any",
})

LibUSC:RegisterParameter("Seconds Since Event", {
    type = "Number",
    category = CATEGORY,
    configString = "Seconds since {1}",
    description = "The amount of time that has passed since the given event occurred",
    receivesUpdates = true,
    ParameterTypes = {
        "Event",
    },
    
    Call = function(self)
        return GetTime() - self.Parameters[1]:GetValue()
    end,
})

LibUSC:RegisterParameter("Event Occurred Recently", {
    type = "Truth",
    category = CATEGORY,
    configString = "{1} Within the Last {2} Seconds",
    description = "True when an event has occurred within a specific time range",
    receivesUpdates = true,
    ParameterTypes = {
        "Event",
        "Number",
    },
    
    Init = function(self)
        self:SetParameter(2, LibUSC:Create("User-Entered Number", 5))
    end,
    
    Call = function(self)
        return GetTime() - self.Parameters[1]:GetValue() < self.Parameters[2]:GetValue()
    end,
})

LibUSC:RegisterParameter("Minimap Ping", {
    type = "Event",
    category = CATEGORY,
    configString = "Minimap Ping",
    description = "Occurs when the player or a teammate clicks on the minimap",
    Events = {"MINIMAP_PING"},
    value = -math.huge,
    
    OnEvent = function(self, event)
        return self:SetValue(GetTime())
    end,
})
LibUSC:SetTypeDefault("Event", "Minimap Ping")

LibUSC:RegisterParameter("Quest Acceptance", {
    type = "Event",
    category = CATEGORY,
    configString = "Quest Acceptance",
    description = "Occurs when the player accepts a quest",
    Events = {"QUEST_ACCEPTED"},
    value = -math.huge,
    
    OnEvent = function(self, event)
        return self:SetValue(GetTime())
    end,
})

LibUSC:RegisterParameter("Quest Update", {
    type = "Event",
    category = CATEGORY,
    configString = "Quest Update",
    description = "Occurs when quest status changes",
    Events = {"QUEST_WATCH_UPDATE"},
    value = -math.huge,
    
    OnEvent = function(self, event)
        return self:SetValue(GetTime())
    end,
})

LibUSC:RegisterParameter("Change in Value", {
    type = "Event",
    category = CATEGORY,
    configString = "Change in {1}",
    description = "Occurs when the given value changes",
    ParameterTypes = {
        "Any",
    },
    value = -math.huge,
    
    Call = function(self)
        return GetTime()
    end,
})

LibUSC:RegisterParameter("Chat Message Received", {
	type = "Event",
	configString = "Chat message received",
	description = "Occurs when a chat message is received",
	Events = {
		"CHAT_MSG_CHANNEL", 
		"CHAT_MSG_SAY", 
		-- "CHAT_MSG_SYSTEM", 
		"CHAT_MSG_YELL",
		"CHAT_MSG_EMOTE",
		-- Guild
		"CHAT_MSG_GUILD",
		"CHAT_MSG_OFFICER",
		-- Party
		"CHAT_MSG_PARTY",
		"CHAT_MSG_PARTY_LEADER",
		-- Raid
		"CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_RAID_WARNING",
		-- NPCs
		"CHAT_MSG_MONSTER_SAY",
		"CHAT_MSG_MONSTER_EMOTE",
		"CHAT_MSG_MONSTER_YELL",
		"CHAT_MSG_MONSTER_WHISPER",
	},
	value = -math.huge,

	OnEvent = function(self, event)
		self:SetValue(GetTime())
	end,
})

-- Forever port: the time a chat window last displayed a line. Hooking AddMessage catches every
-- line a window shows (whispers, system, loot, addon output) and only the channels the player
-- shows in a window. The combat log is left out: it adds a line for every combat event.
local lastChatLineTime = -math.huge
local hookedChatFrames = {}

local function OnChatLineAdded(frame)
	if ( frame ~= COMBATLOG ) then
		lastChatLineTime = GetTime()
	end
end

local function HookChatFrames()
	local names = {}
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		table.insert(names, "ChatFrame" .. i)
	end
	for _, name in ipairs(CHAT_FRAMES or {}) do -- includes the whisper windows opened during play
		table.insert(names, name)
	end
	for _, name in ipairs(names) do
		local frame = _G[name]
		if ( type(frame) == "table" and frame.AddMessage and not hookedChatFrames[frame] ) then
			hookedChatFrames[frame] = true
			hooksecurefunc(frame, "AddMessage", OnChatLineAdded)
		end
	end
end

HookChatFrames()
if ( FCF_OpenTemporaryWindow ) then
	hooksecurefunc("FCF_OpenTemporaryWindow", HookChatFrames)
end

LibUSC:RegisterParameter("Message Received in Chat", {
	type = "Truth",
	category = CATEGORY,
	configString = "Chat message within the last {1} seconds",
	description = "True for the given number of seconds after any chat window shows a new line "
		.."(the combat log is ignored)",
	receivesUpdates = true,
	ParameterTypes = {
		"Number",
	},

	Init = function(self)
		self:SetParameter(1, LibUSC:Create("User-Entered Number", 10))
	end,

	Call = function(self)
		return GetTime() - lastChatLineTime < self.Parameters[1]:GetValue()
	end,
})

LibUSC:RegisterParameter("Player is Typing in Chat", {
	type = "Truth",
	category = CATEGORY,
	configString = "Player is typing in chat",
	description = "True while a chat input box is open",
	receivesUpdates = true,

	Call = function(self)
		local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
		if ( focus ~= nil and not issecretvalue(focus) and focus.chatFrame ~= nil ) then
			return true
		end
		for i = 1, (NUM_CHAT_WINDOWS or 10) do
			local editBox = _G["ChatFrame" .. i .. "EditBox"]
			if ( editBox ~= nil ) then
				local hasFocus = editBox:HasFocus()
				if ( not issecretvalue(hasFocus) and hasFocus ) then
					return true
				end
			end
		end
		return false
	end,
})

LibUSC:RegisterParameter("Player Gained XP", {
	type = "Event",
	configString = "Player gained XP",
	description = "Occurs when you gain XP",
	Events = {"PLAYER_XP_UPDATE"},
	value = -math.huge,
    
    OnEvent = function(self, event, unit)
		if ( unit == "player" ) then
			self:SetValue(GetTime())
		end
    end,
})

LibUSC:RegisterParameter("Player Gained Level", {
	type = "Event",
	configString = "Player gained a level",
	description = "Occurs when you gain a level",
	Events = {"PLAYER_LEVEL_UP"},
	value = -math.huge,

	OnEvent = function(self, event)
		self:SetValue(GetTime())
	end,
})

LibUSC:RegisterParameter("Frame Is Visible", {
	type = "Truth",
	category = CATEGORY,
	description = "True when the given frame is visible",
	configString = "{1} is visible",
	receivesUpdates = true,
	
	ParameterTypes = {
		"Frame",
	},
	
	Call = function(self)
		if ( self.Parameters[1]:GetValue() == nil ) then
			self.Parameters[1]:SetValue()
		end
		
		local frame = self.Parameters[1]:GetValue()
		
		if frame == nil then
			return false
		end
		local alpha = frame:GetAlpha()
		return issecretvalue(alpha) or alpha > 0
	end,
	
	IsValid = function(self)
		if ( self.Parameters[1]:GetValue() ~= nil ) then
			return true
		else
			return false, "Frame must not be empty"
		end
	end,
})

LibUSC:RegisterParameter("Cursor Is Holding Something", {
	type = "Truth",
	description = "True when the cursor is holding something (e.g. spell, item)",
	configString = "Cursor is Holding Something",
	
	Events = {
		"ACTIONBAR_SHOWGRID", -- NOTE: edge case: when picking up a spell in a spell book, CURSOR_UPDATE fires before GetCursorInfo returns correct info
		"CURSOR_CHANGED", -- Forever port: replaces CURSOR_UPDATE
	},
	
	Call = function(self)
		return GetCursorInfo() ~= nil
	end,
})

-- Mainline
if ( IS_MAINLINE_FAMILY ) then		
	LibUSC:RegisterParameter("Focus", { 
		version = 2,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by hunters",
		value = 2,
	})

	LibUSC:RegisterParameter("Runes", { 
		version = 2,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by death knights",
		value = 5,
	})

	LibUSC:RegisterParameter("Runic Power", { 
		version = 2,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by death knights",
		value = 6,
	})

	LibUSC:RegisterParameter("Soul Shards", { 
		version = 2,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by warlocks",
		value = 7,
	})

	LibUSC:RegisterParameter("Eclipse", { 
		version = 2,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by balance druids",
		value = 8,
	})

	LibUSC:RegisterParameter("Holy Power", { 
		version = 2,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by paladins",
		value = 9,
	})

	LibUSC:RegisterParameter("Alternate Power", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used in boss encounters",
		value = 10,
	})

	LibUSC:RegisterParameter("Maelstrom", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by shamans",
		value = 11,
	})

	LibUSC:RegisterParameter("Chi", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by monks",
		value = 12,
	})

	LibUSC:RegisterParameter("Insanity", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by priests",
		value = 13,
	})

	LibUSC:RegisterParameter("Arcane Charges", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by mages",
		value = 16,
	})

	LibUSC:RegisterParameter("Fury", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by demon hunters",
		value = 17,
	})

	LibUSC:RegisterParameter("Pain", { 
		version = 1,
		type = "Power",
		category = CATEGORY,
		description = "Power type used by demon hunters",
		value = 18,
	})
	
-- Classic
elseif ( WOW_PROJECT_ID == WOW_PROJECT_CLASSIC ) then	
	LibUSC:RegisterParameter("Macro", { 
		version = 3,
		type = "Truth",
		category = CATEGORY,
		description = "True when the given macro condition is true (square brackets [] are required)",
		ParameterTypes = {
			"Text",
		},
		Events = {
			"PLAYER_REGEN_DISABLED",
			"PLAYER_REGEN_ENABLED",
			"UNIT_OTHER_PARTY_CHANGED",
			"UNIT_PET",
			"PLAYER_TARGET_CHANGED",
			"MODIFIER_STATE_CHANGED",
			"ACTIONBAR_PAGE_CHANGED",
			"UPDATE_BONUS_ACTIONBAR",
			"PLAYER_ENTERING_WORLD",
			"UPDATE_SHAPESHIFT_FORM",
			"UPDATE_STEALTH",
			"RAID_ROSTER_UPDATE",
		},
		receivesUpdates = true,
		configString = "Macro Condition: {1}",
		
		Init = function(self)
			self:SetParameter(1, LibUSC:Create("User-Entered Text", "[flying]"))
		end,
		
		Call = function(self)
			return SecureCmdOptionParse(self.Parameters[1]:GetValue()) ~= nil
		end,
		
		IsValid = function(self)
			local condition = string.match(self.Parameters[1]:GetValue(), "(%[.*%])");
			if not condition then
				return false, "Condition(s) must use square brackets (e.g. [flying])"
			end
			return true
		end,
	})
end

-- Mainline or Burning Crusade Classic
if ( IS_MAINLINE_FAMILY or WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC ) then
	LibUSC:RegisterParameter("Macro", { 
		version = 3,
		type = "Truth",
		category = CATEGORY,
		description = "True when the given macro condition is true (square brackets [] are required)",
		ParameterTypes = {
			"Text",
		},
		Events = {
			"PLAYER_REGEN_DISABLED",
			"PLAYER_REGEN_ENABLED",
			"PLAYER_FOCUS_CHANGED",
			"UNIT_OTHER_PARTY_CHANGED",
			"UNIT_PET",
			"PLAYER_TARGET_CHANGED",
			"MODIFIER_STATE_CHANGED",
			"ACTIONBAR_PAGE_CHANGED",
			"UPDATE_BONUS_ACTIONBAR",
			"PLAYER_ENTERING_WORLD",
			"UPDATE_SHAPESHIFT_FORM",
			"UPDATE_STEALTH",
			"RAID_ROSTER_UPDATE",
		},
		receivesUpdates = true,
		configString = "Macro Condition: {1}",
		
		Init = function(self)
			self:SetParameter(1, LibUSC:Create("User-Entered Text", "[flying]"))
		end,
		
		Call = function(self)
			return SecureCmdOptionParse(self.Parameters[1]:GetValue()) ~= nil
		end,
		
		IsValid = function(self)
			local condition = string.match(self.Parameters[1]:GetValue(), "(%[.*%])");
			if not condition then
				return false, "Condition(s) must use square brackets (e.g. [flying])"
			end
			return true
		end,
	})

	LibUSC:RegisterParameter("Arena", { 
		version = 2,
		type = "Instance",
		category = CATEGORY,
		description = "A 2 to 5 player PvP instance",
		value = "arena",
	})
end

-- TODO:
-- Level Up
-- Zone Change
-- Quest Acceptance
-- Buff Application
-- Cooldown Completion
-- Reactive Ability 