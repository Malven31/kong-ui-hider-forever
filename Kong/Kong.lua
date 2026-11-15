local	_G, assert, ipairs, math, next, pairs, pcall, print, setmetatable, string, table, tonumber, tostring, type, xpcall
=		_G, assert, ipairs, math, next, pairs, pcall, print, setmetatable, string, table, tonumber, tostring, type, xpcall
local	CreateFrame, debugstack, GetMouseFoci, GetMouseFocus, GetRealmName, GetTime, hooksecurefunc, IsAddOnLoaded, StaticPopup_Show, strsplit, UnitName, WOW_PROJECT_CLASSIC, WOW_PROJECT_ID, WOW_PROJECT_MAINLINE
=		CreateFrame, debugstack, GetMouseFoci, GetMouseFocus, GetRealmName, GetTime, hooksecurefunc, IsAddOnLoaded, StaticPopup_Show, strsplit, UnitName, WOW_PROJECT_CLASSIC, WOW_PROJECT_ID, WOW_PROJECT_MAINLINE


local N, A = ... -- Addon (N)ame, (A)ddon Table
local R = A.CLASSES -- Class (R)epository


local DUMMY_FRAME = CreateFrame("frame") -- used for references to avoid abundant rawget calls when dealing with dummy functions

-- Forever port: a region whose alpha was set from a secret returns a secret from GetAlpha,
-- which can't be compared or computed with. Treat it as fully visible.
local issecretvalue = issecretvalue or function() return false end
-- Forever port: IsForbidden can return a secret, which can't be tested.
local function GetAccessibleParent(region)
	local isForbidden = region:IsForbidden()
	if issecretvalue(isForbidden) or isForbidden then
		return nil
	end
	return region:GetParent()
end
local function GetRegionAlpha(region)
	local alpha = region:GetAlpha()
	if issecretvalue(alpha) then
		return 1
	end
	return alpha
end
local FADER = R.Fader.construct()

-- Forever port: some windows are built from sibling frames that are all children of UIParent, so
-- fading the main frame does not fade the rest. Kong fades the main frame and makes the siblings
-- follow it: they copy its alpha, and the mouse over a sibling counts as the mouse over the main frame.
local function GetFrameName(frame)
	local name = frame:GetName()
	if ( issecretvalue(name) ) then return nil end
	return name
end

-- Every chat window except ChatFrame1, including the whisper windows opened during play.
-- The edit boxes are left out on purpose: Blizzard hides an inactive edit box by setting its alpha,
-- which a linked alpha would overwrite. Blizzard shows the edit box itself when the player types.
local CHAT_EXTRA_FRAMES = {
	"GeneralDockManager",
	"ChatFrameMenuButton",
	"ChatFrameChannelButton",
	"QuickJoinToastButton",
	"ChatFrameToggleVoiceDeafenButton",
	"ChatFrameToggleVoiceMuteButton",
	"ChatFrame1Tab",
}
local function GetChatSiblingNames()
	local names = {unpack(CHAT_EXTRA_FRAMES)}
	local chatFrames = {}
	for i = 2, (NUM_CHAT_WINDOWS or 10) do
		chatFrames["ChatFrame" .. i] = true
	end
	for _, name in ipairs(CHAT_FRAMES or {}) do
		chatFrames[name] = true
	end
	chatFrames["ChatFrame1"] = nil
	for name in pairs(chatFrames) do
		table.insert(names, name)
		table.insert(names, name .. "Tab")
	end
	return names
end

local MULTI_FRAME_WINDOWS = {
	{
		-- Details!: DetailsBaseFrameN is the main frame, DetailsRowFrameN holds the bars and
		-- Details_SwitchButtonFrameN lies over the window to catch clicks.
		main = "^DetailsBaseFrame(%d+)$",
		GetSiblingNames = function(id)
			return {"DetailsRowFrame" .. id, "Details_SwitchButtonFrame" .. id}
		end,
		-- Details! sets its windows back to full alpha after it builds them, and again on zone and
		-- combat changes (its auto transparency). Kong always overrides their alpha, as if the
		-- "Override Alpha" option were on, or Details! would show a window Kong has hidden.
		forceOverrideAlpha = true,
	},
	{
		-- Blizzard chat: ChatFrame1 is the main frame. The other windows, the tabs, the dock and
		-- the buttons beside the chat follow it.
		main = "^(ChatFrame1)$",
		GetSiblingNames = GetChatSiblingNames,
	},
}
-- Details! parts are never offered in the config, even before their window is registered.
local DETAILS_MAIN_PATTERN = MULTI_FRAME_WINDOWS[1].main
local HIDDEN_WINDOW_PART_PATTERNS = {
	"^DetailsRowFrame%d+$",
	"^Details_SwitchButtonFrame%d+$",
	"^Details_WindowFrameAntiMenuOverlap%d+$",
}

local LinkedRegions = {} -- main region -> array of sibling regions
local LinkOwner = {} -- sibling region -> main region
local HiddenLinkedRegions = {} -- siblings that Kong hid at zero alpha
local NO_ALPHA_CHANGE = function() end

-- Returns the siblings of a main frame and its window description, or nil when the region is not
-- the main frame of a window.
local function FindSiblings(region)
	local name = GetFrameName(region)
	if ( name == nil ) then return nil end

	for _, window in ipairs(MULTI_FRAME_WINDOWS) do
		local id = string.match(name, window.main)
		if ( id ~= nil ) then
			local siblings = {}
			for _, siblingName in ipairs(window.GetSiblingNames(id)) do
				local sibling = _G[siblingName]
				if ( type(sibling) == "table" and type(sibling.GetObjectType) == "function" ) then
					table.insert(siblings, sibling)
				end
			end
			return siblings, window
		end
	end
end

-- True when one of the frame's ancestors is in the given set.
local function HasAncestorIn(frame, set)
	local parent = GetAccessibleParent(frame)
	while ( parent ~= nil ) do
		if ( set[parent] ) then return true end
		parent = GetAccessibleParent(parent)
	end
	return false
end

local function ReleaseSibling(sibling)
	LinkOwner[sibling] = nil
	sibling.SetAlpha = nil
	DUMMY_FRAME.SetAlpha(sibling, 1)
	if ( HiddenLinkedRegions[sibling] ) then
		HiddenLinkedRegions[sibling] = nil
		DUMMY_FRAME.Show(sibling)
	end
end

-- Links the siblings of a main frame. Safe to call again: windows open, close and move between
-- frames during play (a docked chat tab, for example, becomes a child of GeneralDockManager).
function A.UpdateLinks(region)
	local found, window = FindSiblings(region)
	if ( found == nil ) then return end

	-- A sibling registered on its own, or linked to another window, keeps its own settings
	local candidates = {[region] = true}
	for _, sibling in ipairs(found) do
		if ( sibling ~= region and not Kong_Frames[sibling]
				and (LinkOwner[sibling] == nil or LinkOwner[sibling] == region) ) then
			candidates[sibling] = true
		end
	end

	-- A frame inside the main frame or inside another sibling already follows its parent's alpha;
	-- linking it as well would apply the alpha twice.
	local linked, isLinked = {}, {}
	for sibling in pairs(candidates) do
		if ( sibling ~= region and not HasAncestorIn(sibling, candidates) ) then
			table.insert(linked, sibling)
			isLinked[sibling] = true
		end
	end

	for _, previous in ipairs(LinkedRegions[region] or {}) do
		if ( not isLinked[previous] ) then
			ReleaseSibling(previous)
		end
	end

	local setting = Kong_Frames[region]
	for _, sibling in ipairs(linked) do
		if ( LinkOwner[sibling] == nil ) then
			LinkOwner[sibling] = region
			DUMMY_FRAME.SetAlpha(sibling, GetRegionAlpha(region))
			if ( setting and setting.overrideAlpha ) then
				sibling.SetAlpha = NO_ALPHA_CHANGE
			end
		end
	end

	-- Applied on every pass, so it holds even after the option is unticked in the config.
	-- Kong_UnregisterFrame and Kong_Unload remove it from the main frame, UnlinkRegions from the siblings.
	if ( window.forceOverrideAlpha and setting ~= nil ) then
		region.SetAlpha = NO_ALPHA_CHANGE
		for _, sibling in ipairs(linked) do
			sibling.SetAlpha = NO_ALPHA_CHANGE
		end
	end

	LinkedRegions[region] = linked
	R.Fader.setLinkedRegions(FADER, region, linked)
end

function A.UnlinkRegions(region)
	local linked = LinkedRegions[region]
	if ( linked == nil ) then return end

	for _, sibling in ipairs(linked) do
		ReleaseSibling(sibling)
	end

	LinkedRegions[region] = nil
	R.Fader.setLinkedRegions(FADER, region, nil)
end

-- The addon that owns a sibling can raise its alpha after Kong faded it: Details! resets the bars'
-- alpha while it builds its windows after a reload. A sibling is never shown more than its main
-- frame; its owner can still make it more transparent (Blizzard fades the chat tabs, for example).
function A.ClampLinkedAlpha()
	for region, linked in pairs(LinkedRegions) do
		local alpha = GetRegionAlpha(region)
		for _, sibling in ipairs(linked) do
			local siblingAlpha = DUMMY_FRAME.GetAlpha(sibling)
			if ( not issecretvalue(siblingAlpha) and siblingAlpha > alpha + 0.001 ) then
				DUMMY_FRAME.SetAlpha(sibling, alpha)
			end
		end
	end
end

-- A sibling that gets its own Kong settings stops following its main frame.
function A.DetachLinkedRegion(region)
	local owner = LinkOwner[region]
	if ( owner ~= nil ) then
		A.UpdateLinks(owner)
	end
end

-- Forever port: the chat edit boxes are children of UIParent, so they don't fade with the chat. They
-- can't be linked like the other chat parts: Blizzard and Prat hide an inactive box through its alpha,
-- and copying the chat's alpha over it showed boxes that should have stayed hidden. Instead Kong leaves
-- the alpha to the box's owner and only ever lowers it: a box without keyboard focus is never more
-- visible than its chat window, while Kong fades that window. This also hides a box left open: when a
-- box loses focus with text in it (clicking the world while typing), Blizzard keeps it active and
-- shown, and nothing hides it until the player goes back to it.
local ChatEditBoxes = {} -- edit box -> {chatFrame = its chat window, alpha = the alpha its owner last set}

local function UpdateChatEditBoxAlpha(editBox, state)
	if ( Kong_Frames[editBox] ~= nil ) then return end -- registered on its own: Kong fades it itself
	local isShown = editBox:IsShown()
	if ( issecretvalue(isShown) or not isShown ) then return end

	local alpha = state.alpha
	local hasFocus = editBox:HasFocus()
	if ( not issecretvalue(hasFocus) and not hasFocus and A.FindFirstTrackedRegion(state.chatFrame) ~= nil ) then
		local chatAlpha = state.chatFrame:GetEffectiveAlpha()
		if ( not issecretvalue(chatAlpha) and chatAlpha < alpha ) then
			alpha = chatAlpha
		end
	end

	local current = DUMMY_FRAME.GetAlpha(editBox)
	if ( issecretvalue(current) or math.abs(current - alpha) > 0.001 ) then
		DUMMY_FRAME.SetAlpha(editBox, alpha)
	end
end

-- Runs after every SetAlpha call made through the box itself (Blizzard's and Prat's). Kong's own calls
-- go through DUMMY_FRAME, so they are not taken for the owner's choice.
local function OnChatEditBoxSetAlpha(editBox, alpha)
	local state = ChatEditBoxes[editBox]
	if ( state == nil or issecretvalue(alpha) or type(alpha) ~= "number" ) then return end
	state.alpha = math.max(0, math.min(1, alpha))
	pcall(UpdateChatEditBoxAlpha, editBox, state)
end

-- Safe to call again: picks up the whisper windows opened during play.
function A.HookChatEditBoxes()
	local names = {}
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		table.insert(names, "ChatFrame" .. i)
	end
	for _, name in ipairs(CHAT_FRAMES or {}) do
		table.insert(names, name)
	end
	for _, name in ipairs(names) do
		local chatFrame = _G[name]
		local editBox = type(chatFrame) == "table" and chatFrame.editBox
		if ( type(editBox) == "table" and ChatEditBoxes[editBox] == nil
				and type(editBox.SetAlpha) == "function" and type(chatFrame.GetEffectiveAlpha) == "function" ) then
			local alpha = DUMMY_FRAME.GetAlpha(editBox)
			ChatEditBoxes[editBox] = {
				chatFrame = chatFrame,
				alpha = issecretvalue(alpha) and 1 or alpha,
			}
			hooksecurefunc(editBox, "SetAlpha", OnChatEditBoxSetAlpha)
		end
	end
end

-- Every frame: the chat's alpha changes during its fades without the box being told.
function A.UpdateChatEditBoxes()
	for editBox, state in pairs(ChatEditBoxes) do
		pcall(UpdateChatEditBoxAlpha, editBox, state)
	end
end

-- True for a frame that belongs to a multi-frame window but is not its main frame.
function Kong_IsWindowPart(frame)
	local current = frame
	while ( current ~= nil and current ~= UIParent ) do
		if ( LinkOwner[current] ) then
			return true
		end
		local name = GetFrameName(current)
		if ( name ~= nil ) then
			if ( current ~= frame and string.match(name, DETAILS_MAIN_PATTERN) ) then
				return true
			end
			for _, pattern in ipairs(HIDDEN_WINDOW_PART_PATTERNS) do
				if ( string.match(name, pattern) ) then
					return true
				end
			end
		end
		current = GetAccessibleParent(current)
	end
	return false
end

R.Fader.addListener(FADER, "FADE_STARTED",
		function(obj, event, region, fromAlpha, toAlpha, duration, smoothing, startDelay, endDelay)
			local setting = Kong_Frames[region]

			if ( setting.hideAtZeroAlpha and GetRegionAlpha(region) == 0 ) then
				DUMMY_FRAME.Show(region)
			end
			-- Show only the siblings Kong hid, so a window that Details closed stays closed
			for _, sibling in ipairs(LinkedRegions[region] or {}) do
				if ( HiddenLinkedRegions[sibling] ) then
					HiddenLinkedRegions[sibling] = nil
					DUMMY_FRAME.Show(sibling)
				end
			end
		end,
		{}
)
R.Fader.addListener(FADER, "FADE_FINISHED",
		function(obj, event, region)
			local setting = Kong_Frames[region]

			if ( setting.hideAtZeroAlpha and GetRegionAlpha(region) == 0 ) then
				DUMMY_FRAME.Hide(region)
				for _, sibling in ipairs(LinkedRegions[region] or {}) do
					if ( DUMMY_FRAME.IsShown(sibling) ) then
						HiddenLinkedRegions[sibling] = true
						DUMMY_FRAME.Hide(sibling)
					end
				end
			end
		end,
		{}
)


BINDING_HEADER_KONG = "Kong UI Hider - Forever"
BINDING_NAME_KONG_ENABLE = "Enable UI Fading"
BINDING_NAME_KONG_DISABLE = "Disable UI Fading"
BINDING_NAME_KONG_TOGGLE = "Toggle UI Fading On/Off"
BINDING_NAME_KONG_CONFIG = "Open Config GUI"
local VERSION = "1.6a"

Kong_Frames = {}
Kong_Profiles = {}

local lastMouseFocus = nil
local lastFocusStart = nil -- the tracked region the mouse focus belongs to
local lastMouseStart = nil

local CANNOT_SAVE = "Nameless frames cannot be saved."
local PROFILE_RESET = "Current profile %q has been reset."
local WELCOME = "New character detected. Type |cFF33FF99/Kong|r to configure."

StaticPopupDialogs["KONG_RESET"] = {
	text = "Are you sure you want to delete all settings from the Kong profile \"%s\"?",
	button1 = "Reset",
	button2 = CANCEL,
	OnAccept = function(self)

		Kong_Unload()
		Kong_Profiles[Kong_Settings.profile] = nil
		A.LoadSettings()

		Kong_Info(PROFILE_RESET, Kong_Settings.profile)
	end,
	showAlert = 1,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- The defaults for all triggers
local TriggerDefaults = {
	secondsIn = .2,
	secondsOut = 1,
	secondsTillOut = 0,
	alphaIn = 1,
	alphaOut = 0,
}

function Kong_Error(str, ...)
	print("|cFFFF2222Kong Error:|r "..string.format(str, ...))
end

function Kong_Warning(str, ...)
	print("|cFFFF9922Kong Warning:|r "..string.format(str, ...))
end

function Kong_Info(str, ...)
	print("|cFF33FF99Kong:|r "..string.format(str, ...))
end

local LibUSC = LibStub("LibUserSpecifiedConditions", true)
if not LibUSC then
	Kong_Error("Kong does not appear to have been installed correctly. Note: A full restart of "
			 .."World of Warcraft is required when upgrading from a previous version of Kong.")
	return
end

-- Dummy condition
local MouseoverTypeName = "Frame has Mouse Focus"
LibUSC:RegisterParameter(MouseoverTypeName, {
	type = "Truth",
	isHidden = true,
	value = false,
})

function Kong_OverrideAlpha(region, override)
	assert(Kong_Frames[region] ~= nil)

	local regions = {region, unpack(LinkedRegions[region] or {})}
	for _, overridden in ipairs(regions) do
		if ( override ) then
			overridden.SetAlpha = function() end
		else
			overridden.SetAlpha = nil
		end
	end
end

function Kong_Fade(region, fromAlpha, toAlpha, duration, startDelay)
	if ( Kong_Settings.enabled and (KongConfig == nil or not KongConfig:IsShown()) ) then
		R.Fader.fade(FADER, region, nil, toAlpha, duration, nil, startDelay)
	end
end

function A.FadeIn(region, condition)
	condition.refs = condition.refs + 1
	if ( condition.refs == 1 ) then
		A.CalculateFadeIn(region)
	end
end

function A.CalculateFadeIn(region)
	local setting = Kong_Frames[region]
	local currentAlpha = GetRegionAlpha(region)
	local chosenTrigger

	-- NOTE: choose the trigger with the highest alpha, with the fastest speed
	for i, trigger in ipairs(setting) do
		if ( trigger.refs > 0 ) then
			chosenTrigger = chosenTrigger or trigger
			
			local speed = math.abs(trigger.alphaIn - trigger.alphaOut) / trigger.secondsIn
			local otherSpeed = math.abs(chosenTrigger.alphaIn - chosenTrigger.alphaOut) / chosenTrigger.secondsIn
			
			if ( trigger.alphaIn > chosenTrigger.alphaIn or (trigger.alphaIn == chosenTrigger.alphaIn and speed > otherSpeed) ) then
				chosenTrigger = trigger
			end
		end
	end
	
	if ( chosenTrigger ~= nil ) then
		local endAlpha = chosenTrigger.alphaIn
		local speed = math.abs(chosenTrigger.alphaIn - chosenTrigger.alphaOut) / chosenTrigger.secondsIn
		local duration = math.abs(currentAlpha - endAlpha) / speed
		
		Kong_Fade(region, currentAlpha, endAlpha, duration)
	end
end

function A.FadeOut(region, condition)
	condition.refs = condition.refs - 1
	assert(condition.refs >= 0, "ref < 0 for region: " .. tostring(region:GetName() or region))
	if ( condition.refs == 0 ) then
		local rate = (condition.alphaOut - condition.alphaIn) / condition.secondsOut
		local displacement = (condition.alphaIn - GetRegionAlpha(region)) / rate
		condition.lastFadeTime = GetTime() + displacement
		Kong_CalculateFadeOut(region)
	end
end

function Kong_CalculateFadeOut(region)
	local setting = Kong_Frames[region]
	local currentAlpha = GetRegionAlpha(region)
	local endAlpha = setting.TriggerDefaults.alphaOut
	local duration = 0
	local delay = setting.TriggerDefaults.secondsTillOut
	local chosenTrigger

	for i, trigger in ipairs(setting) do
		if ( trigger.refs > 0 ) then
			if ( trigger.alphaIn >= currentAlpha ) then return end

			endAlpha = math.max(endAlpha, trigger.alphaIn)
		elseif ( trigger.lastFadeTime ~= nil ) then
			chosenTrigger = chosenTrigger or trigger

			local now = GetTime()
			local sinceTrue = now - trigger.lastFadeTime
			local otherSinceTrue = now - chosenTrigger.lastFadeTime
			
			local speed = math.abs(trigger.alphaOut - trigger.alphaIn) / trigger.secondsOut
			local otherSpeed = math.abs(chosenTrigger.alphaOut - chosenTrigger.alphaIn) / chosenTrigger.secondsOut

			if ( sinceTrue < otherSinceTrue or (sinceTrue == otherSinceTrue and speed < otherSpeed) ) then
				chosenTrigger = trigger
			end
		end
	end

	if ( chosenTrigger ~= nil ) then
		local speed = math.abs(chosenTrigger.alphaOut - chosenTrigger.alphaIn) / chosenTrigger.secondsOut
		duration = math.abs(endAlpha - currentAlpha) / speed
		delay = chosenTrigger.secondsTillOut
	end

	Kong_Fade(region, currentAlpha, endAlpha, duration, delay)
end

function Kong_FindGlobalIndex(region)
	if ( issecretvalue(region) ) then return nil end -- Forever port: children can be secret

	local name = region:GetName()
	if ( issecretvalue(name) ) then name = nil end
	
	if ( name ) then
		return '["' .. name .. '"]'
	end
	
	for k, v in pairs(_G) do
		if ( v == region ) then
			local keyType = type(k)
			if ( keyType == "string" ) then
				return '["' .. k .. '"]'
			elseif ( keyType == "number" or keyType == "boolean" ) then
				return "[" .. tostring(k) .. "]"
			end
		end
	end
	
	for i, child in pairs{region:GetChildren()} do
		name = Kong_FindGlobalIndex(child)
		if ( name ) then
			return name .. ":GetParent()"
		end
	end
end

-- Forever port: finds the frame a saved path names, such as ["ChatFrame1"] or
-- ["SomeAddon"]["bars"][2]:GetParent(), without running the path as code. Kong_FindGlobalIndex and
-- KongConfig's "Save As" only build paths of that shape. The original read them with loadstring, which
-- would also run any code that a hand-edited or shared settings file put in a path's place.
local GET_PARENT = ":GetParent()"

function A.ResolveIndex(index)
	if ( type(index) ~= "string" ) then return nil end

	local value, position, hasKey = _G, 1, false
	while ( true ) do
		local key, nextPosition = string.match(index, '^%["(.-)"%]()', position)
		if ( key == nil ) then
			local literal
			literal, nextPosition = string.match(index, '^%[([^%]"]+)%]()', position)
			if ( literal == nil ) then break end
			if ( literal == "true" ) then
				key = true
			elseif ( literal == "false" ) then
				key = false
			else
				key = tonumber(literal)
				if ( key == nil ) then return nil end
			end
		end
		if ( type(value) ~= "table" ) then return nil end
		value = value[key]
		position = nextPosition
		hasKey = true
	end
	if ( not hasKey ) then return nil end

	while ( string.sub(index, position, position + #GET_PARENT - 1) == GET_PARENT ) do
		if ( type(value) ~= "table" or type(value.GetParent) ~= "function" ) then return nil end
		value = value:GetParent()
		position = position + #GET_PARENT
	end
	if ( position <= #index ) then return nil end -- anything else in the path: refuse it
	return value
end

function A.CreateTrigger(Frame)

	local Trigger = {}
	setmetatable(Trigger, {__index = Kong_Frames[Frame].TriggerDefaults or TriggerDefaults})

	if Kong_Frames[Frame].TriggerDefaults then
		Trigger.refs = 0
	else
		Trigger.Frame = Frame
	end

	return Trigger
end

function Kong_RegisterFrame(region)
	Kong_Frames[region] = {}
	local index = Kong_FindGlobalIndex(region)
	if ( index ~= nil ) then
		Kong_Frames[region].index = index
	else
		Kong_Frames[region].index = {}
		Kong_Warning(CANNOT_SAVE)
	end
	Kong_Frames[region].version = VERSION
	A.DetachLinkedRegion(region)
	A.UpdateLinks(region)
	Kong_Frames[region].TriggerDefaults = A.CreateTrigger(region)
	Kong_Frames[region].Mouseover = Kong_AddTrigger(region, LibUSC:Create("Condition", LibUSC:Create(MouseoverTypeName)))
	Kong_AddTrigger(region, LibUSC:Create("Condition", LibUSC:Create("Unit in Combat")))
end

function Kong_UnregisterFrame(region)
	for i = #Kong_Frames[region], 1, -1 do
		Kong_RemoveTrigger(region, Kong_Frames[region][i])
	end
	Kong_OverrideAlpha(region, false)
	Kong_Fade(region, 1, 1, 0)
	A.UnlinkRegions(region)
	local index = Kong_Frames[region].index
	for name, group in pairs(Kong_Settings.Groups) do
		if ( group[index] ~= nil ) then
			group[index] = nil
			if ( next(group) == nil ) then
				Kong_Settings.Groups[name] = nil
			end
		end
	end
	Kong_Frames[region] = nil
end

function A.OnConditionStateChange(region, trigger)
	if ( trigger.Condition:IsMet() ) then
		A.FadeIn(region, trigger)
	else
		A.FadeOut(region, trigger)
	end
end

function Kong_AddTrigger(region, condition)
	local trigger = A.CreateTrigger(region)
	trigger.Condition = condition
	trigger.Condition:AddListener(A.OnConditionStateChange, region, trigger)
	table.insert(Kong_Frames[region], trigger)
	if ( trigger.Condition:IsMet() ) then
		A.FadeIn(region, trigger)
	end
	return trigger
end

function Kong_RemoveTrigger(region, trigger)
	if ( trigger.Condition:IsMet() ) then
		A.FadeOut(region, trigger)
	end
	trigger.Condition:RemoveListener(A.OnConditionStateChange)
	LibUSC:Deflate(trigger.Condition)
	for i, v in ipairs(Kong_Frames[region]) do
		if ( v == trigger ) then
			table.remove(Kong_Frames[region], i)
			break
		end
	end
end

function Kong_AddFrameToGroup(region, name)
	Kong_Settings.Groups[name] = Kong_Settings.Groups[name] or {}
	local group = Kong_Settings.Groups[name]
	local index = Kong_Frames[region].index
	if ( group[index] == nil ) then
		group[index] = region
		return true
	end
end

function Kong_RemoveFrameFromGroup(region, name)
	local group = Kong_Settings.Groups[name]
	local index = Kong_Frames[region].index
	if ( group ~= nil and group[index] ~= nil ) then
		group[index] = nil
		if ( next(group) == nil ) then
			Kong_Settings.Groups[name] = nil
		end
		return true
	end
end

function A.Enable()
	Kong_Settings.enabled = true
	for Frame in pairs(Kong_Frames) do
		Kong_CalculateFadeOut(Frame)
	end
end

function A.Disable()
	for Frame in pairs(Kong_Frames) do
		Kong_Fade(Frame, 1, 1, 0)
	end
	Kong_Settings.enabled = false
end

function Kong_RenameFrame(region, newIndex)
	local index = Kong_Frames[region].index
	for name, group in pairs(Kong_Settings.Groups) do
		if ( group[index] ~= nil ) then
			group[index] = nil
			group[newIndex] = region
		end
	end
	Kong_Frames[region].index = newIndex
end

function A.LoadSettings()
	if ( Kong_Initialized ) then return end
	Kong_Initialized = true
	
	if ( not Kong_Settings or not Kong_Settings.profile ) then
		local playerName = string.lower( UnitName("player") )
		local playerServer = string.lower( string.gsub(GetRealmName(), " ", "_") )
		local profileName = playerName .. "_of_" .. playerServer
		
		Kong_Settings = {
			profile = profileName,
			enabled = true,
		}
	end

	Kong_Settings.profile = string.gsub(Kong_Settings.profile, " ", "_")
	
	if ( not Kong_Profiles[Kong_Settings.profile] ) then
		Kong_Profiles[Kong_Settings.profile] = {
			Frames = {},
			Groups = {},
		}
	end
	
	setmetatable(Kong_Settings, {__index = Kong_Profiles[Kong_Settings.profile]})

	Kong_Profiles[Kong_Settings.profile].version = VERSION

	A.LoadFrames()

	if ( not Kong_Settings.enabled ) then
	   Kong_Warning("Kong is currently disabled. Use |cFF33FF99/kong toggle|r to enable it.")
	end
end

function A.LoadFrames()
	for i = #Kong_Settings.Frames, 1, -1 do
		local setting = Kong_Settings.Frames[i]
		
		-- Forever port: the saved path is parsed, never run as code (see A.ResolveIndex)
		local isFound, region = pcall(A.ResolveIndex, setting.index)

		if (
				isFound
				and region
				and type(region.IsObjectType) == "function"
				and region:IsObjectType("Region") -- make sure it is a region; ticket #5
				and not Kong_Frames[region]
		) then
			setting.loader = nil
			Kong_Frames[region] = setting
			table.remove(Kong_Settings.Frames, i)

			setmetatable(setting.TriggerDefaults, {__index = TriggerDefaults})
			setting.TriggerDefaults.Frame = region
			A.DetachLinkedRegion(region)
			A.UpdateLinks(region)

			if ( setting.overrideAlpha ) then
				Kong_OverrideAlpha(region, true)
			end
			
			for i, trigger in ipairs(setting) do
				setmetatable(trigger, {__index = setting.TriggerDefaults})
				trigger.refs = 0
				LibUSC:Inflate(trigger.Condition)
				trigger.Condition:AddListener(A.OnConditionStateChange, region, trigger)
				
				if ( MouseoverTypeName == trigger.Condition.Parameters[1]:GetName() ) then
					setting.Mouseover = trigger
				end
			end

			if ( Kong_Settings.enabled ) then
				Kong_CalculateFadeOut(region)
			end
			
			for i, trigger in ipairs(setting) do
				if ( trigger.Condition:IsMet() ) then
					A.FadeIn(region, trigger)
				end
			end
			
			for name, group in pairs(Kong_Settings.Groups) do
				if ( group[setting.index] ) then
					for i = 1, group[setting.index] do
						A.FadeIn(region, setting.Mouseover)
					end
					group[setting.index] = region
				end
			end
		end
	end

	-- Forever port: pick up windows opened since the last pass, such as a new whisper window
	for region in pairs(LinkedRegions) do
		A.UpdateLinks(region)
	end
	A.HookChatEditBoxes()
end

function Kong_Unload()
	for region, settings in pairs(Kong_Frames) do
		Kong_OverrideAlpha(region, false)
		Kong_Fade(region, 1, 1, 0)
		A.UnlinkRegions(region)

		for i, trigger in ipairs(settings) do
			trigger.refs = nil
			trigger.lastFadeTime = nil
			trigger.Condition:RemoveListener(A.OnConditionStateChange)
			LibUSC:Deflate(trigger.Condition)
		end
		
		settings.loader = nil
		settings.Mouseover = nil
		settings.TriggerDefaults.Frame = nil
		
		Kong_Frames[region] = nil
		if ( type(settings.index) ~= "table" ) then
			table.insert(Kong_Settings.Frames, settings)
		end
	end
	
	if ( MinimapParent ) then
		MinimapParent.KongAlphaAnimation:GetScript("OnFinished")()
	end
	
	-- Forever port: a profile without mouseover groups made this fail at logout ("table expected, got nil")
	for name, group in pairs(Kong_Settings.Groups or {}) do
		for index in pairs(group) do
			group[index] = 0
		end
	end
	
	Kong_Frames = {}
	lastMouseFocus = nil
	lastFocusStart = nil
	lastMouseStart = nil
	Kong_Initialized = false
end

-- A linked sibling counts as part of its main frame, so the mouse over a Details bar reveals the window.
-- A chat edit box counts as part of its chat window, so the mouse over a faded box reveals the chat.
local function GetTrackingParent(region)
	local editBox = ChatEditBoxes[region]
	return LinkOwner[region] or (editBox and editBox.chatFrame) or GetAccessibleParent(region)
end

function A.FindFirstTrackedRegion(region)
	while ( region ~= nil and Kong_Frames[region] == nil ) do
		region = GetTrackingParent(region)
	end
	return region
end

function A.ForEachTrackedRegion(region, func, ...)
	while ( region ~= nil ) do
		if ( Kong_Frames[region] ~= nil ) then func(region, ...) end
		region = GetTrackingParent(region)
	end
end

-- Forever port: the text area of a chat window does not take the mouse, so the mouse focus there is
-- whatever lies behind the chat and the window never counted as moused over. For multi-frame
-- windows, the cursor being inside the main frame or a sibling counts as the mouse over the window.
local function IsCursorOver(frame)
	local isVisible = frame:IsVisible()
	if ( issecretvalue(isVisible) or not isVisible ) then return false end
	local isOver = frame:IsMouseOver()
	return not issecretvalue(isOver) and isOver
end

function A.FindHoveredWindow()
	for region, linked in pairs(LinkedRegions) do
		if ( Kong_Frames[region] ~= nil ) then
			if ( IsCursorOver(region) ) then
				return region
			end
			for _, sibling in ipairs(linked) do
				if ( IsCursorOver(sibling) ) then
					return region
				end
			end
		end
	end
end

function A.MouseoverRegionFader(region, func, additive)
	local settings = Kong_Frames[region]
	for name, group in pairs(Kong_Settings.Groups) do
		if ( group[settings.index] ~= nil ) then
			for index, groupRegion in pairs(group) do
				if ( type(groupRegion) == "table" ) then -- TODO: remove value-type ambiguity
					func(groupRegion, Kong_Frames[groupRegion].Mouseover)
				else
					group[index] = groupRegion + additive
				end
			end
		end
	end
	func(region, settings.Mouseover)
end

local FRAME_FIND_PERIOD = 1.0
local frameFindTimer = 0

function A.OnUpdate(self, elapsed)
	frameFindTimer = frameFindTimer - elapsed
	if frameFindTimer <= 0 then
		frameFindTimer = FRAME_FIND_PERIOD
		A.LoadFrames()
	end

	A.ClampLinkedAlpha()
	A.UpdateChatEditBoxes()

	local mouseFocus
	if ( GetMouseFocus ~= nil ) then
		mouseFocus = GetMouseFocus()
	else
		mouseFocus = GetMouseFoci()[1]
	end
	if ( mouseFocus ~= lastMouseFocus ) then
		lastFocusStart = mouseFocus ~= nil and A.FindFirstTrackedRegion(mouseFocus) or nil
		lastMouseFocus = mouseFocus
	end

	-- The geometric test runs every frame: the mouse focus does not change while the cursor moves
	-- across the world, so it can't tell when the cursor enters a window.
	local mouseStart = lastFocusStart or A.FindHoveredWindow()
	if ( mouseStart ~= lastMouseStart ) then
		if ( mouseStart ~= nil ) then
			A.ForEachTrackedRegion(mouseStart, A.MouseoverRegionFader, A.FadeIn, 1)
		end
		if ( lastMouseStart ~= nil ) then
			A.ForEachTrackedRegion(lastMouseStart, A.MouseoverRegionFader, A.FadeOut, -1)
		end
		lastMouseStart = mouseStart
	end
end

function A.OnEvent(self, event, arg1, ...)

	if event == "ADDON_LOADED" then
		if arg1 == "Kong" and not Kong_Settings then
			Kong_Info(WELCOME)
		end
	elseif event == "PLAYER_LOGIN" then

		A.LoadSettings()
		
		hooksecurefunc("CreateFrame", function() frameFindTimer = 0; end)
		KongUIFader:SetScript("OnUpdate", A.OnUpdate)
	elseif event == "PLAYER_LOGOUT" then
		xpcall(Kong_Unload, function(message) Kong_Settings.error = message.."\n"..debugstack() end)
	end
end

-- Fix for TukUI PetBattleHider -- TODO remove after v1.6
if TukuiPetBattleHider then
	for _,TukChild in pairs({TukuiPetBattleHider:GetChildren()}) do
		TukChild:SetParent(UIParent)
		local unit = TukChild:GetAttribute("unit")
		if unit then
			RegisterUnitWatch(TukChild, true)
			RegisterStateDriver(TukChild, "visibility", "[@"..unit..",exists,nopetbattle] show; hide")
		else
			RegisterStateDriver(TukChild, "visibility", "[nopetbattle] show; hide")
		end
	end
	UnregisterStateDriver(TukuiPetBattleHider, "visibility")
	TukuiPetBattleHider:Hide()
	TukuiPetBattleHider = UIParent
end

-- The event receiver frame
KongUIFader = CreateFrame("Frame")
KongUIFader:SetScript("OnEvent", A.OnEvent)

KongUIFader:RegisterEvent("ADDON_LOADED")
KongUIFader:RegisterEvent("PLAYER_LOGIN")
KongUIFader:RegisterEvent("PLAYER_LOGOUT")