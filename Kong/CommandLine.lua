local	pairs, print, string, table
=		pairs, print, string, table
local	strsplit
=		strsplit
local N, A = ...


local CANNOT_DELETE_CURRENT_PROFILE = "Cannot delete the current profile. Use |cFF33FF99/kong profile reset|r to reset it."
local PROFILE_ALREADY_LOADED = "Profile %q is already the current profile."
local PROFILE_DELETED = "Profile %q deleted."
local HELP_PROFILE_COMMANDS = "|cFFBBBBFFKong UI Hider - Forever|r profile commands ( |cFF33FF99/kong profile|r ):"
local HELP_PROFILE_LOAD = "|cFF33FF99load <name>|r: loads the specified profile."
local HELP_PROFILE_CREATE = "|cFF33FF99create <name>|r: creates a new profile with the given name."
local HELP_PROFILE_DELETE = "|cFF33FF99delete <name>|r: deletes the specified profile."
local HELP_PROFILE_LIST = "|cFF33FF99list|r: lists all available profiles."
local HELP_PROFILE_CURRENT = "|cFF33FF99current|r: prints the current profile name."
local HELP_PROFILE_RESET = "|cFF33FF99reset|r: resets the current profile."
local ENABLED = "Enabled."
local ALREADY_ENABLED = "Already enabled."
local DISABLED = "Disabled."
local ALREADY_DISABLED = "Already disabled."
local NO_KONG_CONFIG = "Kong Config is either disabled or not installed. Defaulting to command-line interface..."
local HELP_COMMANDS = "|cFFBBBBFFKong UI Hider - Forever|r commands ( |cFF33FF99/kong|r ):"
local HELP_TOGGLE = "|cFF33FF99enable / disable / toggle|r: enables or disables fading of the user interface."
local HELP_PROFILE = "|cFF33FF99profile|r: manages saved Kong configurations and allows for configuration sharing between characters."
local HELP_MINIMAP = "|cFF33FF99minimap|r: hides or shows the minimap button."
local HELP_POWERLOG ="|cFF33FF99powerlog|r: records mana events for 90 seconds into the saved variables (debugging)."
local PROFILE_LOADED = "Profile %q loaded."
local NOW_USING_PROFILE = "Now using profile %q."
local PROFILE_ALREADY_EXISTS = "Profile %q already exists."
local INVALID_COMMAND = " command unknown (Type |cFF33FF99/kong help|r for help)."
local UNKNOWN_OPTION = "Unknown option: %q (Type |cFF33FF99/kong %s|r for help)."
local PROFILE_NAME_REQUIRED = "Profile name required."
local NO_SUCH_PROFILE = "Profile %q does not exist. Use |cFF33FF99/kong profile list|r to see a list of available profiles."


function A.ProfileCommandHandler(command, name)
	if ( command == nil ) then
		print(HELP_PROFILE_COMMANDS)
		print(HELP_PROFILE_LOAD)
		print(HELP_PROFILE_CREATE)
		print(HELP_PROFILE_DELETE)
		print(HELP_PROFILE_LIST)
		print(HELP_PROFILE_CURRENT)
		print(HELP_PROFILE_RESET)
		
	elseif ( command == "create" ) then
		if ( name == nil ) then Kong_Error(PROFILE_NAME_REQUIRED) return end
		if ( Kong_Profiles[name] ~= nil ) then Kong_Error(PROFILE_ALREADY_EXISTS, name) return end
		
		Kong_Unload()
		Kong_Settings.profile = name
		A.LoadSettings()
		Kong_Info(NOW_USING_PROFILE, name)

	elseif ( command == "delete" ) then
		if ( name == nil ) then Kong_Error(PROFILE_NAME_REQUIRED) return end
		if ( name == Kong_Settings.profile ) then Kong_Error(CANNOT_DELETE_CURRENT_PROFILE) return end
		if ( Kong_Profiles[name] == nil ) then Kong_Error(NO_SUCH_PROFILE, name) return end
		
		Kong_Profiles[name] = nil
		Kong_Info(PROFILE_DELETED, name)
		
	elseif ( command == "list" ) then
		local names = {}
		for name in pairs(Kong_Profiles) do
			table.insert(names, name)
		end
		table.sort(names)
		for i, name in pairs(names) do
			Kong_Info(name)
		end
		Kong_Info(#names .. " profile(s)")
		
	elseif ( command == "load" ) then
		if ( name == nil ) then Kong_Error(PROFILE_NAME_REQUIRED) return end
		if ( Kong_Profiles[name] == nil ) then Kong_Error(NO_SUCH_PROFILE, name) return end
		if ( name == Kong_Settings.profile ) then Kong_Error(PROFILE_ALREADY_LOADED, name) return end
		
		Kong_Unload()
		Kong_Settings.profile = name
		A.LoadSettings()
		Kong_Info(PROFILE_LOADED, name)
		
	elseif ( command == "reset" ) then
		A.ResetCommandHandler()

	elseif ( command == "current" ) then
		Kong_Info("Current profile is: " .. Kong_Settings.profile)
		
	else
		Kong_Error(UNKNOWN_OPTION, command, "profile")
	end
end


function A.ResetCommandHandler()
	StaticPopup_Show("KONG_RESET", Kong_Settings.profile)
end


function Kong_EnableCommandHandler()
	if not Kong_Settings.enabled then
		A.Enable()
		Kong_Info(ENABLED)
	else
		Kong_Error(ALREADY_ENABLED)
	end
end


function Kong_DisableCommandHandler()
	if Kong_Settings.enabled then
		A.Disable()
		Kong_Info(DISABLED)
	else
		Kong_Error(ALREADY_DISABLED)
	end
end


function Kong_ToggleCommandHandler()
	if Kong_Settings.enabled then
		Kong_DisableCommandHandler()
	else
		Kong_EnableCommandHandler()
	end
end


-- Forever port: /kong powerlog. For POWER_LOG_SECONDS, writes into Kong_Settings.powerLog (saved at
-- logout or /reload) one line per player power event, and one line whenever a "Unit Power is Low"
-- condition changes value. Shows whether the player's mana is secret and when the conditions flip.
local POWER_LOG_SECONDS = 90
local POWER_LOG_EVENTS = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_SPELLCAST_SUCCEEDED",
	"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}
local powerLogFrame, powerLogTicker, lastPowerConditions

local issecretvalue = issecretvalue or function() return false end

local function Describe(value)
	if ( issecretvalue(value) ) then return "secret" end
	return tostring(value)
end

local function QuerySecrets(name, ...)
	local func = C_Secrets and C_Secrets[name]
	if ( func == nil ) then return "n/a" end
	local ok, value = pcall(func, ...)
	if ( not ok ) then return "error" end
	if ( not issecretvalue(value) and type(value) == "number" and Enum and Enum.SecrecyLevel ) then
		for levelName, level in pairs(Enum.SecrecyLevel) do
			if ( level == value ) then return levelName end
		end
	end
	return Describe(value)
end

local function DescribePowerConditions()
	local parts = {}
	for region, setting in pairs(Kong_Frames) do
		for _, trigger in ipairs(setting) do
			local condition = trigger.Condition
			local param = condition and condition.Parameters and condition.Parameters[1]
			if ( param ~= nil and param.name == "Unit Power is Low" ) then
				local index = type(setting.index) == "string" and setting.index or "?"
				table.insert(parts, index .. " " .. tostring(param.value))
			end
		end
	end
	return table.concat(parts, ", ")
end

local function AddPowerLogLine(text)
	table.insert(Kong_Settings.powerLog, string.format("%.2f %s", GetTime(), text))
end

local function StopPowerLog()
	if ( powerLogFrame ) then powerLogFrame:UnregisterAllEvents() end
	if ( powerLogTicker ) then powerLogTicker:Cancel() end
	powerLogTicker = nil
	AddPowerLogLine("end")
	Kong_Info("Power log done. Type |cFF33FF99/reload|r so it is saved to disk.")
end

function A.StartPowerLog()
	if ( powerLogTicker ) then
		Kong_Error("The power log is already recording.")
		return
	end
	Kong_Settings.powerLog = {}
	AddPowerLogLine(string.format("start | power type %s | ShouldUnitPowerBeSecret %s | ShouldUnitPowerMaxBeSecret %s"
		.. " | GetPowerTypeSecrecy(mana) %s | combat %s",
		Describe(UnitPowerType("player")), QuerySecrets("ShouldUnitPowerBeSecret", "player", 0),
		QuerySecrets("ShouldUnitPowerMaxBeSecret", "player", 0), QuerySecrets("GetPowerTypeSecrecy", 0),
		tostring(InCombatLockdown())))

	if ( powerLogFrame == nil ) then
		powerLogFrame = CreateFrame("Frame")
		powerLogFrame:SetScript("OnEvent", function(_, event, unit, powerToken, spellID)
			if ( event ~= "PLAYER_REGEN_DISABLED" and event ~= "PLAYER_REGEN_ENABLED" and unit ~= "player" ) then return end
			if ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
				AddPowerLogLine(string.format("%s spell %s", event, Describe(spellID)))
				return
			end
			AddPowerLogLine(string.format("%s %s | mana %s / %s | combat %s", event, tostring(powerToken or ""),
				Describe(UnitPower("player", 0)), Describe(UnitPowerMax("player", 0)), tostring(InCombatLockdown())))
		end)
	end
	for _, event in ipairs(POWER_LOG_EVENTS) do
		powerLogFrame:RegisterEvent(event)
	end

	lastPowerConditions = nil
	local stopAt = GetTime() + POWER_LOG_SECONDS
	powerLogTicker = C_Timer.NewTicker(0.25, function()
		local conditions = DescribePowerConditions()
		if ( conditions ~= lastPowerConditions ) then
			lastPowerConditions = conditions
			AddPowerLogLine("Unit Power is Low: " .. (conditions ~= "" and conditions or "none in this profile"))
		end
		if ( GetTime() >= stopAt ) then
			StopPowerLog()
		end
	end)
	Kong_Info("Recording mana events for " .. POWER_LOG_SECONDS .. " seconds: cast a few spells out of combat, "
		.. "then wait until your mana is full.")
end


function A.CommandHandler(args)
	local args = {strsplit(" ", string.lower(args))}
	local command = args[1]

	if ( command == nil or command == "" ) then
		if ( C_AddOns.LoadAddOn("KongConfig") ) then
			KongConfig_Show()
		else
			Kong_Warning(NO_KONG_CONFIG)
			print(HELP_COMMANDS)
			print(HELP_TOGGLE)
			print(HELP_PROFILE)
		end
	elseif ( KongConfig and KongConfig.frame:IsShown() ) then
		Kong_Error("The config screen must be closed to issue /kong commands.")
	elseif ( command == "enable" ) then
		Kong_EnableCommandHandler()
	elseif ( command == "disable" ) then
		Kong_DisableCommandHandler()
	elseif ( command == "toggle" ) then
		Kong_ToggleCommandHandler()
	elseif ( command == "profile" ) then
		if ( #args > 2 ) then
			local name = table.concat(args, "_", 3)
			A.ProfileCommandHandler(args[2], name)
		else
			A.ProfileCommandHandler(args[2])
		end
	elseif ( command == "reset" ) then
		A.ResetCommandHandler()
	elseif ( command == "minimap" ) then
		A.ToggleMinimapButton()
	elseif ( command == "powerlog" ) then
		A.StartPowerLog()
	elseif ( command == "help" ) then
		print(HELP_COMMANDS)
		print(HELP_TOGGLE)
		print(HELP_PROFILE)
		print(HELP_MINIMAP)
		print(HELP_POWERLOG)
	else
		Kong_Error('"' .. command .. '"' .. INVALID_COMMAND)
	end
end


SLASH_KONG1 = "/kong"
SlashCmdList["KONG"] = A.CommandHandler