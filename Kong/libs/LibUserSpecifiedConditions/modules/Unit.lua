local LibUSC = LibStub and LibStub("LibUserSpecifiedConditions", true)
if not LibUSC then return end

local CATEGORY = "Unit"

-- Forever port helpers --------------------------------------------------------
-- Forever (interface 16001) runs the Mainline engine, including secret values.
local issecretvalue = issecretvalue or function() return false end
local IS_MAINLINE_FAMILY = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
    or (WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)

-- Blizzard's LowHealthFrame turns on at or below this health percentage.
local LOW_HEALTH_FRAME_PERCENT = 35
-- Out of combat health regenerates in ticks, so UNIT_HEALTH keeps firing until health is full.
-- Seconds without a health change after which a unit counts as "no longer changing".
local HEALTH_SETTLE_SECONDS = 3
-- Kept out of the parameter so it is never written to SavedVariables.
local recentHealthChange = setmetatable({}, {__mode = "k"})

-- UnitPower is secret for every unit, the player included, unless Blizzard flags the power type as
-- never secret ("SecretWhenUnitPowerRestricted" in Forever's API docs: unlike the aura and cooldown
-- predicates, it does not depend on combat). Mana is secret, so its percentage can't be tested.
-- Instead, "below 100%" means "changed recently": mana, energy and focus refill in ticks until full,
-- and each tick fires UNIT_POWER_UPDATE. Rage and runic power drain instead, so it doesn't apply.
local REFILLING_POWER = {[0] = true, [2] = true, [3] = true} -- mana, focus, energy
-- Seconds without a power event after which the power counts as full: one regen tick (2 seconds in
-- Classic, not yet measured on Forever) plus a margin. Nothing readable says a tick was the last one,
-- so this is the delay between "full" and the condition turning false.
local POWER_SETTLE_SECONDS = 2.5
-- The five-second rule: after a cast that costs mana, spirit regeneration stops for 5 seconds, so
-- there are no ticks although mana isn't full. Mana counts as not full until one tick after that.
local MANA_SPEND_SECONDS = 5 + POWER_SETTLE_SECONDS
local recentPowerChange = setmetatable({}, {__mode = "k"})
local recentManaSpend = setmetatable({}, {__mode = "k"})

-- True when the spell costs mana (the same test as Five Second Rule). An unreadable answer counts as
-- a cost: at worst the frame stays a few seconds longer.
local function SpellCostsMana(spellID)
    if spellID == nil or issecretvalue(spellID) then
        return true
    end
    local getPowerCost = (C_Spell and C_Spell.GetSpellPowerCost) or GetSpellPowerCost
    if not getPowerCost then
        return true
    end
    local ok, costs = pcall(getPowerCost, spellID)
    if not ok or issecretvalue(costs) then
        return true
    end
    if type(costs) ~= "table" then
        return false
    end
    for _, cost in ipairs(costs) do
        local powerType, amount, minCost = cost.type, cost.cost, cost.minCost
        if issecretvalue(powerType) or issecretvalue(amount) or issecretvalue(minCost) then
            return true
        end
        if powerType == 0 and ((amount or 0) > 0 or (minCost or 0) > 0) then
            return true
        end
    end
    return false
end

-- current/maximum, or nil when either one is secret.
local function SafeRatio(current, maximum)
    if issecretvalue(current) or issecretvalue(maximum) then
        return nil
    end
    return current / maximum
end

-- UnitCastingInfo/UnitChannelInfo return nothing when idle, so even a secret result means "casting".
local function HasValue(value)
    return issecretvalue(value) or value ~= nil
end
-- -----------------------------------------------------------------------------

LibUSC:RegisterParameter("Player", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The player-controlled character",
    value = "player",
})
LibUSC:SetTypeDefault("Unit", "Player")

LibUSC:RegisterParameter("Target", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The currently targeted unit",
    value = "target",
    Events = {"PLAYER_TARGET_CHANGED"},
    OnEvent = function(self)
        self:FireValueChanged()
    end,
})

LibUSC:RegisterParameter("Pet", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The pet of the player-controlled character",
    value = "pet",
})

LibUSC:RegisterParameter("Mouseover Unit", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The unit currently under the mouse cursor",
    value = "mouseover",
    Events = {"UPDATE_MOUSEOVER_UNIT"},
    OnEvent = function(self)
        self:FireValueChanged()
    end,
})

LibUSC:RegisterParameter("Party Member", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The party member at the given index (1-4)",
    ParameterTypes = {
        "Number",
    },
    configString = "Party Member: {1}",
    
    Call = function(self)
        return "party"..self.Parameters[1]:GetValue()
    end,
    
    IsValid = function(self)
        if (self.Parameters[1]:GetValue() < 1) or (self.Parameters[1]:GetValue() > 4) then
            return false, "Party member index must be between 1 and 4"
        end
        return true
    end,
})

LibUSC:RegisterParameter("Pet of Party Member", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The pet of the party member at the given index (1-4)",
    ParameterTypes = {
        "Number",
    },
    configString = "Pet of Party Member: {1}",
    
    Call = function(self)
        return "partypet"..self.Parameters[1]:GetValue()
    end,
    
    IsValid = function(self)
        if (self.Parameters[1]:GetValue() < 1) or (self.Parameters[1]:GetValue() > 4) then
            return false, "Party member index must be between 1 and 4"
        end
        return true
    end,
})

LibUSC:RegisterParameter("Raid Member", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The raid member at the given index (1-40)",
    ParameterTypes = {
        "Number",
    },
    configString = "Raid Member: {1}",
    
    Call = function(self)
        return "raid"..self.Parameters[1]:GetValue()
    end,
    
    IsValid = function(self)
        if (self.Parameters[1]:GetValue() < 1) or (self.Parameters[1]:GetValue() > 40) then
            return false, "Party member index must be between 1 and 40"
        end
        return true
    end,
})

LibUSC:RegisterParameter("Pet of Raid Member", {
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "The pet of the raid member at the given index (1-40)",
    ParameterTypes = {
        "Number",
    },
    configString = "Pet of Raid Member: {1}",
    
    Call = function(self)
        return "raidpet"..self.Parameters[1]:GetValue()
    end,
    
    IsValid = function(self)
        if (self.Parameters[1]:GetValue() < 1) or (self.Parameters[1]:GetValue() > 40) then
            return false, "Party member index must be between 1 and 40"
        end
        return true
    end,
})

LibUSC:RegisterParameter("Target of Unit", { 
    version = 4,
    type = "Unit",
    category = CATEGORY,
    description = "The target of the given unit",
    Events = {"UNIT_TARGET"},
    ParameterTypes = {
        "Unit",
    },
    configString = "Target of {1}",
    
    Init = function(self)
        self:SetParameter(1, LibUSC:Create("Target"))
    end,
    
    Call = function(self)
        return self.Parameters[1]:GetValue().."target"
    end,
    
    OnEvent = function(self, event, unit)
        if unit == self.Parameters[1]:GetValue() then
            self:FireValueChanged()
        end
    end,
})

LibUSC:RegisterParameter("Unit Name", { 
    version = 2,
    type = "Text",
    category = CATEGORY,
    description = "The name of the given unit",
    ParameterTypes = {
        "Unit",
    },
    configString = "Name of {1}",
    
    Call = function(self)
        return UnitName(self.Parameters[1]:GetValue())
    end,
})

LibUSC:RegisterParameter("Unit in Combat", { 
    version = 2,
    type = "Truth",
    category = CATEGORY,
    description = "True when the player-controlled character is in combat",
    Events = {"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"},
    configString = "Player is in Combat",
    
    Call = function(self)
        return not not InCombatLockdown()
    end,
    
    OnEvent = function(self, event)
        self:SetValue(event == "PLAYER_REGEN_DISABLED")
    end,
})

LibUSC:RegisterParameter("Unit is Resting", { 
    version = 3,
    type = "Truth",
    category = CATEGORY,
    description = "True when the player-controlled character is resting",
    Events = {"PLAYER_UPDATE_RESTING", "PLAYER_ENTERING_WORLD"},
    configString = "Player is Resting",
    
    Call = function(self)
        return not not IsResting()
    end,
})

LibUSC:RegisterParameter("Unit is Casting", { 
    version = 2,
    type = "Truth",
    category = CATEGORY,
    description = "True when the given unit is casting",
    Events = {
        "UNIT_SPELLCAST_START", 
        "UNIT_SPELLCAST_STOP", 
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
    },
    ParameterTypes = {
        "Unit",
    },
    configString = "{1} is Casting",
    
    Call = function(self)
        return HasValue(UnitCastingInfo(self.Parameters[1]:GetValue()))
            or HasValue(UnitChannelInfo(self.Parameters[1]:GetValue()))
    end,
    
    OnEvent = function(self, event, unit)
        if (unit == self.Parameters[1]:GetValue()) then
            self:SetValue((event == "UNIT_SPELLCAST_START") 
                       or (event == "UNIT_SPELLCAST_CHANNEL_START"))
        end
    end,
})

LibUSC:RegisterParameter("Unit is Mounted", { 
    version = 2,
    type = "Truth",
    category = CATEGORY,
    description = "True when the player-controlled character is mounted",
    Events = {
        "COMPANION_UPDATE",
        "SPELL_UPDATE_USABLE",
    },
    configString = "Player is Mounted",
    
    Call = function(self)
		return IsMounted()
    end,
    
    OnEvent = function(self, event, arg1)
		if ( event == "COMPANION_UPDATE" and arg1 == "MOUNT" ) then
			self._check = true
		elseif ( event == "SPELL_UPDATE_USABLE" and self._check ) then
			self._check = false
			self:SetValue()
		end
    end,
})

LibUSC:RegisterParameter("Unit Exists", { 
    version = 3,
    type = "Truth",
    category = CATEGORY,
    description = "True when the given unit exists",
    ParameterTypes = {
        "Unit",
    },
    configString = "{1} Exists",
    
    Init = function(self)
        self:SetParameter(1, LibUSC:Create("Target"))
    end,
    
    Call = function(self)
        return UnitExists(self.Parameters[1]:GetValue())
    end,
})

LibUSC:RegisterParameter("Unit is Unit", { 
    version = 2,
    type = "Truth",
    category = CATEGORY,
    description = "True when two units are the same "
    .."(e.g. Player and Target of Target are often the same unit)",
    ParameterTypes = {
        "Unit",
        "Unit",
    },
    configString = "{1} is the same unit as {2}",
    
    Call = function(self)
        local unit1, unit2 = self.Parameters[1]:GetValue(), self.Parameters[2]:GetValue()
        if C_Secrets and C_Secrets.CanCompareUnitTokens and not C_Secrets.CanCompareUnitTokens(unit1, unit2) then
            return self.value
        end
        return UnitIsUnit(unit1, unit2)
    end,
})

LibUSC:RegisterParameter("Unit Health", { 
    version = 2,
    type = "Number",
    category = CATEGORY,
    description = "The current health of a given unit",
    Events = {"UNIT_HEALTH"},
    ParameterTypes = {
        "Unit",
    },
    configString = "Health of {1}",
    
    Call = function(self)
        return UnitHealth(self.Parameters[1]:GetValue())
    end,
    
    OnEvent = function(self, event, unit)
        if (unit == self.Parameters[1]:GetValue()) then
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit Health Maximum", { 
    version = 2,
    type = "Number",
    category = CATEGORY,
    description = "The maximum health of a given unit",
    Events = {"UNIT_MAXHEALTH"},
    ParameterTypes = {
        "Unit",
    },
    configString = "Maximum Health of {1}",
    
    Call = function(self)
        return UnitHealthMax(self.Parameters[1]:GetValue())
    end,
    
    OnEvent = function(self, event, unit)
        if (unit == self.Parameters[1]:GetValue()) then
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit Health (Percent)", { 
    version = 2,
    type = "Number",
    category = CATEGORY,
    description = "The current percent health of a given unit",
    Events = {"UNIT_HEALTH", "UNIT_MAXHEALTH"},
    ParameterTypes = {
        "Unit",
    },
    configString = "Percent Health of {1}",
    
    Call = function(self)
        local unit = self.Parameters[1]:GetValue()
        return SafeRatio(UnitHealth(unit), UnitHealthMax(unit)) or self.value or 0
    end,
    
    OnEvent = function(self, event, unit)
        if (unit == self.Parameters[1]:GetValue()) then
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit Health is Low", { 
    version = 1,
    type = "Truth",
    category = CATEGORY,
    description = "True when the current health of a given unit is below a specified threshold",
    Events = {"UNIT_HEALTH", "UNIT_MAXHEALTH"},
    receivesUpdates = true, -- Forever port: expires the "health recently changed" window.
    ParameterTypes = {
        "Unit",
        "Number",
    },
    configString = "Health of {1} below {2}%",
    
    Init = function(self)
        self:SetParameter(2, LibUSC:Create("User-Entered Number", 100))
    end,
    
    Call = function(self)
        local unit = self:GetParameter(1):GetValue()
        local percent = self:GetParameter(2):GetValue()
        local ratio = SafeRatio(UnitHealth(unit), UnitHealthMax(unit))
        if ratio ~= nil then
            return ratio < percent/100
        end

        -- Forever port: UnitHealth is secret, so the exact percentage can't be tested.
        -- Use the signals that are public, which approximate the condition.
        if UnitIsDeadOrGhost(unit) then
            return true
        end
        if unit == "player" and percent >= LOW_HEALTH_FRAME_PERCENT and LowHealthFrame then
            local isLow = LowHealthFrame:IsShown()
            if not issecretvalue(isLow) and isLow then
                return true
            end
        end
        if percent >= 100 then -- "not at full health": true while health is still changing
            local changed = recentHealthChange[self]
            return changed ~= nil and GetTime() - changed < HEALTH_SETTLE_SECONDS
        end
        return false
    end,

    OnEvent = function(self, event, unit)
        if (unit == self.Parameters[1]:GetValue()) then
            recentHealthChange[self] = GetTime()
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit is Moving", { 
    version = 2,
    type = "Truth",
    category = CATEGORY,
    description = "True when the given unit is in motion",
    receivesUpdates = true,
    ParameterTypes = {
        "Unit",
    },
    configString = "{1} is Moving",
    
    Call = function(self)
        local speed = GetUnitSpeed(self.Parameters[1]:GetValue())
        if issecretvalue(speed) then
            return self.value
        end
        return speed > 0
    end,
})

LibUSC:RegisterParameter("Unit Speed", { 
    version = 2,
    type = "Number",
    category = CATEGORY,
    description = "The current speed of the given unit in yards per second",
    receivesUpdates = true,
    ParameterTypes = {
        "Unit",
    },
    configString = "Speed of {1}",
    
    Call = function(self)
        return GetUnitSpeed(self.Parameters[1]:GetValue())
    end,
})

LibUSC:RegisterParameter("Unit Speed (Percent)", { 
    version = 2,
    type = "Number",
    category = CATEGORY,
    description = "The current percent speed of the given unit, where running is 100%",
    receivesUpdates = true,
    ParameterTypes = {
        "Unit",
    },
    configString = "Speed of {1}",
    
    Call = function(self)
        local speed = GetUnitSpeed(self.Parameters[1]:GetValue())
        if issecretvalue(speed) then
            return self.value or 0
        end
        return speed / 7
    end,
})

local POWER_NAMES = {
[0] = "MANA",
"RAGE",
"FOCUS",
"ENERGY",
"HAPPINESS",
"RUNES",
"RUNIC_POWER",
"SOUL_SHARDS",
"ECLIPSE",
"HOLY_POWER",
}

LibUSC:RegisterParameter("Unit Power", { 
    version = 3,
    type = "Number",
    category = CATEGORY,
    description = "The current power level (mana, rage, etc.) of a given unit",
    Events = {"UNIT_POWER_UPDATE"},
    ParameterTypes = {
        "Power",
        "Unit",
    },
    configString = "{1} of {2}",
    
    Call = function(self)
        return UnitPower(self.Parameters[2]:GetValue(), self.Parameters[1]:GetValue())
    end,
    
    OnEvent = function(self, event, unit, power)
        if (unit == self.Parameters[2]:GetValue()) and (power == POWER_NAMES[self.Parameters[1]:GetValue()]) then
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit Power Maximum", { 
    version = 3,
    type = "Number",
    category = CATEGORY,
    description = "The maximum power level (mana, rage, etc.) of a given unit",
    Events = {"UNIT_MAXPOWER"},
    ParameterTypes = {
        "Power",
        "Unit",
    },
    configString = "Maximum {1} of {2}",
    
    Call = function(self)
        return UnitPowerMax(self.Parameters[2]:GetValue(), self.Parameters[1]:GetValue())
    end,
    
    OnEvent = function(self, event, unit, power)
        if (unit == self.Parameters[2]:GetValue()) and (power == POWER_NAMES[self.Parameters[1]:GetValue()]) then
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit Power (Percent)", { 
    version = 3,
    type = "Number",
    category = CATEGORY,
    description = "The current percent power (mana, rage, etc.) of a given unit",
    Events = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"},
    ParameterTypes = {
        "Power",
        "Unit",
    },
    configString = "Percent {1} of {2}",
    
    Call = function(self)
        local power = self.Parameters[1]:GetValue()
        local unit = self.Parameters[2]:GetValue()
        return SafeRatio(UnitPower(unit, power), UnitPowerMax(unit, power)) or self.value or 0
    end,
    
    OnEvent = function(self, event, unit, power)
        if (unit == self.Parameters[2]:GetValue()) and (power == POWER_NAMES[self.Parameters[1]:GetValue()]) then
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit Power is Low", { 
    version = 1,
    type = "Truth",
    category = CATEGORY,
    configString = "{1} of {2} below {3}%",
    description = "True when the current power (mana, rage, etc.) of a given unit is below a specified threshold",
    ParameterTypes = {
        "Power",
        "Unit",
        "Number",
    },
    -- Forever port: UNIT_SPELLCAST_SUCCEEDED detects the five-second rule, see MANA_SPEND_SECONDS.
    Events = {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "PLAYER_REGEN_ENABLED", "UNIT_SPELLCAST_SUCCEEDED"},
    receivesUpdates = true, -- Forever port: expires the "power recently changed" window.

    Init = function(self)
        self:SetParameter(3, LibUSC:Create("User-Entered Number", 100))
    end,

    Call = function(self)
        local power = self:GetParameter(1):GetValue()
        local unit = self:GetParameter(2):GetValue()
        local percent = self:GetParameter(3):GetValue()
        local ratio = SafeRatio(UnitPower(unit, power), UnitPowerMax(unit, power))
        if ratio ~= nil then -- readable: a power type flagged never secret, or one the unit doesn't have
            return ratio < percent/100
        end

        -- Forever port: the power is secret, see REFILLING_POWER.
        if percent >= 100 and REFILLING_POWER[power] then
            local now = GetTime()
            local changed, spent = recentPowerChange[self], recentManaSpend[self]
            return (changed ~= nil and now - changed < POWER_SETTLE_SECONDS)
                or (spent ~= nil and now - spent < MANA_SPEND_SECONDS)
        end
        return self.value
    end,

    -- UNIT_POWER_UPDATE/UNIT_MAXPOWER pass (unit, powerToken); UNIT_SPELLCAST_SUCCEEDED passes
    -- (unit, castGUID, spellID).
    OnEvent = function(self, event, unit, arg2, arg3)
        if event == "PLAYER_REGEN_ENABLED" then
            self:SetValue()
            return
        end
        if unit ~= self:GetParameter(2):GetValue() then
            return
        end
        local power = self:GetParameter(1):GetValue()
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if power == 0 and SpellCostsMana(arg3) then
                recentManaSpend[self] = GetTime()
                self:SetValue()
            end
            return
        end
        if arg2 == POWER_NAMES[power] then
            recentPowerChange[self] = GetTime()
            self:SetValue()
        end
    end,
})

LibUSC:RegisterParameter("Unit in Range of Spell", {
	type = "Truth",
	category = CATEGORY,
	description = "True when a specific unit is in range of the given spell",
	configString = "{2} is in Range of {1}",
	receivesUpdates = true,
	
	ParameterTypes = {
		{"Spell", "Pet Spell"},
		"Unit",
	},
	
	Init = function(self)
		self:SetParameter(2, LibUSC:Create("Target"))
	end,
	
	Call = function(self)
		local index = self:GetParameter(1):GetValue()
		
		if ( index ~= nil ) then
			local bookType = self:GetParameter(1):GetType() == "Spell" and "spell" or "pet"
			local unitId = self:GetParameter(2):GetValue()
			
			-- Forever port: the global IsSpellInRange was replaced by C_SpellBook (true / false / nil).
			local bank = bookType == "spell" and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.Pet
			local inRange = C_SpellBook.IsSpellBookItemInRange(index, bank, unitId)
			if issecretvalue(inRange) then
				return self.value
			end
			return inRange == true
		end
	end,
	
	IsValid = function(self)
		if ( self:GetParameter(1):GetValue() ~= nil ) then
			return true
		else
			return false, "Invalid spell"
		end
	end,
})

LibUSC:RegisterParameter("Unit in Instance", {
    version = 2,
    type = "Truth",
    category = CATEGORY,
    configString = "Player in {1}",
    description = "True when the player is in the given type of instance",
    ParameterTypes = {
        "Instance",
    },
    -- Forever port: ZONE_CHANGED_NEW_AREA does not fire on login or /reload, so a condition
    -- evaluated before the world finished loading stayed wrong until the next zone change.
    -- PLAYER_ENTERING_WORLD fires after every loading screen, including login and /reload.
    Events = {"ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD"},
    
    Call = function(self)
        local isInInstance, instanceType = IsInInstance()
        local parameterValue = self:GetParameter(1):GetValue()
        return (isInInstance and parameterValue == "any") or parameterValue == instanceType
    end,
})

LibUSC:RegisterParameter("Unit is Dead", {
	type = "Truth",
	category = CATEGORY,
	description = "True when the given unit is dead",
	configString = "{1} is Dead",
	receivesUpdates = true,
	
	ParameterTypes = {
		"Unit",
	},
	
	Call = function(self)
		return UnitIsDead(self.Parameters[1]:GetValue())
	end,
})

LibUSC:RegisterParameter("Unit is Ghost", {
	type = "Truth",
	category = CATEGORY,
	description = "True when the given unit is a ghost",
	configString = "{1} is a Ghost",
	receivesUpdates = true,
	
	ParameterTypes = {
		"Unit",
	},
	
	Call = function(self)
		return UnitIsGhost(self.Parameters[1]:GetValue())
	end,
})

LibUSC:RegisterParameter("Unit is Dead or Ghost", {
	type = "Truth",
	category = CATEGORY,
	description = "True when the given unit is dead or a ghost",
	configString = "{1} is Dead or a Ghost",
	receivesUpdates = true,
	
	ParameterTypes = {
		"Unit",
	},
	
	Call = function(self)
		return UnitIsDeadOrGhost(self.Parameters[1]:GetValue())
	end,
})

-- Mainline
if ( IS_MAINLINE_FAMILY ) then
	LibUSC:RegisterParameter("Boss", { 
		version = 2,
		type = "Unit",
		category = CATEGORY,
		description = "The boss of the current encounter at the given index (1-4)",
		ParameterTypes = {
			"Number",
		},
		configString = "Boss: {1}",
		
		Call = function(self)
			return "boss"..self.Parameters[1]:GetValue()
		end,
		
		IsValid = function(self)
			if (self.Parameters[1]:GetValue() < 1) or (self.Parameters[1]:GetValue() > 4) then
				return false, "Boss index must be between 1 and 4"
			end
			return true
		end,
	})

	LibUSC:RegisterParameter("Vehicle", {
		version = 2,
		type = "Unit",
		category = CATEGORY,
		description = "The vehicle in which the player-controlled character is currently riding",
		value = "vehicle",
		Events = {"UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE"},
		OnEvent = function(self)
			self:FireValueChanged()
		end,
	})

	LibUSC:RegisterParameter("Player is Interacting with NPC", {
		type = "Truth",
		category = CATEGORY,
		description = "True when the player interacts with a NPC",
		configString = "Player is interacting with a NPC",
		
		Events = {
			"PLAYER_TARGET_CHANGED",
			"GOSSIP_SHOW",
			"GOSSIP_CLOSED",
			"QUEST_COMPLETE",
			"QUEST_DETAIL",
			"QUEST_FINISHED",
			"QUEST_GREETING",
			"QUEST_PROGRESS",
			"BANKFRAME_OPENED",
			"BANKFRAME_CLOSED",
			"MERCHANT_SHOW",
			"MERCHANT_CLOSED",
			"TRAINER_SHOW",
			"TRAINER_CLOSED",
			"SHIPMENT_CRAFTER_OPENED",
			"SHIPMENT_CRAFTER_CLOSED"
		},
		
		Call = function(self)
			return UnitExists("npc")
		end,
	})

	LibUSC:RegisterParameter("Unit in Vehicle", { 
		version = 2,
		type = "Truth",
		category = CATEGORY,
		description = "True when the given unit is riding in a vehicle",
		Events = {"UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE"},
		ParameterTypes = {
			"Unit",
		},
		configString = "{1} is in a Vehicle",
		
		Call = function(self)
			return not not UnitInVehicle(self.Parameters[1]:GetValue())
		end,
		
		OnEvent = function(self, event, unit)
			if (unit == self.Parameters[1]:GetValue()) then
				self:SetValue(event == "UNIT_ENTERED_VEHICLE")
			end
		end,
	})
end

-- Mainline or Burning Crusade Classic
if ( IS_MAINLINE_FAMILY or WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC ) then
	LibUSC:RegisterParameter("Focus Unit", {
		version = 2,
		type = "Unit",
		category = CATEGORY,
		description = "The currently focus-targeted unit",
		value = "focus",
		Events = {"PLAYER_FOCUS_CHANGED"},
		OnEvent = function(self)
			self:FireValueChanged()
		end,
	})

	LibUSC:RegisterParameter("Arena Opponent", {
		version = 2,
		type = "Unit",
		category = CATEGORY,
		description = "The arena opponent at the given index (1-5)",
		ParameterTypes = {
			"Number",
		},
		configString = "Arena Opponent: {1}",
		
		Call = function(self)
			return "arena"..self.Parameters[1]:GetValue()
		end,
		
		IsValid = function(self)
			if (self.Parameters[1]:GetValue() < 1) or (self.Parameters[1]:GetValue() > 5) then
				return false, "Arena opponent index must be between 1 and 5"
			end
			return true
		end,
	})
end

-- Classic or Burning Crusade Classic
if ( WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC ) then
	LibUSC:RegisterParameter("Player is Interacting with NPC", {
		type = "Truth",
		category = CATEGORY,
		description = "True when the player interacts with a NPC",
		configString = "Player is interacting with a NPC",
		
		Events = {
			"PLAYER_TARGET_CHANGED",
			"GOSSIP_SHOW",
			"GOSSIP_CLOSED",
			"QUEST_COMPLETE",
			"QUEST_DETAIL",
			"QUEST_FINISHED",
			"QUEST_GREETING",
			"QUEST_PROGRESS",
			"BANKFRAME_OPENED",
			"BANKFRAME_CLOSED",
			"MERCHANT_SHOW",
			"MERCHANT_CLOSED",
			"TRAINER_SHOW",
			"TRAINER_CLOSED",
		},
		
		Call = function(self)
			return UnitExists("npc")
		end,
	})
end

-- LibUSC:RegisterParameter("Unit in Zone", { 
    -- version = 1,
    -- type = "Truth",
    -- category = CATEGORY,
    -- configString = "Player in {1}",
    -- description = "True when the player is in the given zone (e.g. Arathi Basin)",
    -- ParameterTypes = {
        -- "Text",
    -- },
    -- Events = {"ZONE_CHANGED"},
    
    -- Call = function(self)
        -- local _, instance = IsInInstance()
        -- return instance == self:GetParameter(1):GetValue()
    -- end,
-- })
