local LibUSC = LibStub and LibStub("LibUserSpecifiedConditions", true)
if not LibUSC then return end

local CATEGORY = "Text"

LibUSC:RegisterParameter("User-Entered Text", { 
    version = 2,
    type = "Text",
    category = "User-Entered",
    description = "Custom text that is input by the user",
    isUserEntered = true,
    GetConfigString = function(self)
        return self:GetValue()
    end,
    
    Call = function(self)
        return self:GetValue() or ""
    end,
})
LibUSC:SetTypeDefault("Text", "User-Entered Text")

LibUSC:RegisterParameter("Text Contains Text", { 
    version = 2,
    type = "Truth",
    category = CATEGORY,
    description = "True if a given text is found within the another text",
    ParameterTypes = {
        "Text",
        "Text",
    },
    GetConfigString = function(self)
        return "{1} contains {2}"
    end,
    
    Call = function(self)
        return string.find(self.Parameters[1]:GetValue(), self.Parameters[2]:GetValue(), 1, true) ~= nil
    end,
})

LibUSC:RegisterParameter("Combine Text", { 
    version = 2,
    type = "Text",
    category = CATEGORY,
    description = "Merges two texts together",
    ParameterTypes = {
        "Text",
        "Text",
    },
    GetConfigString = function(self)
        return "Combine {1} and {2}"
    end,
    
    Call = function(self)
        return self.Parameters[1]:GetValue()..self.Parameters[2]:GetValue()
    end,
})

LibUSC:RegisterParameter("Convert Text to Unit", { 
    version = 2,
    type = "Unit",
    category = CATEGORY,
    description = "Converts text (e.g. 'player' or 'Bobthedk') into the corresponding unit",
    ParameterTypes = {
        "Text",
    },
    configString = "Unit: {1}",
    
    Call = function(self)
        return self.Parameters[1]:GetValue()
    end,
})

LibUSC:RegisterParameter("Convert Text to Spell", { 
    type = "Spell",
    category = CATEGORY,
    configString = "Spell: {1}",
    description = "Converts text (e.g. 'Moonfire' or 'Greater Heal') into the corresponding spell",
    ParameterTypes = {
        "Text",
    },
    Events = {
        "SPELLS_CHANGED"
    },
    
    Call = function(self)
        local spellName = self:GetParameter(1):GetValue()
        -- Forever port: the spell tab / spell book globals were replaced by C_SpellBook.
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(C_SpellBook.GetNumSpellBookSkillLines())
        local numSlots = lineInfo and (lineInfo.itemIndexOffset + lineInfo.numSpellBookItems) or 0
        for i=1,numSlots do
            local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
            if info and info.itemType == Enum.SpellBookItemType.Spell and info.name == spellName then
                return i
            end
        end
    end,
})

LibUSC:RegisterParameter("Convert Text to Pet Spell", { 
    type = "Pet Spell",
    category = CATEGORY,
    configString = "Pet Spell: {1}",
    description = "Converts text (e.g. 'Leap' or 'Fire Breath') into the corresponding pet spell",
    ParameterTypes = {
        "Text",
    },
    Events = {
        "SPELLS_CHANGED"
    },
    
    Call = function(self)
        local spellName = self:GetParameter(1):GetValue()
        -- Forever port: see "Convert Text to Spell". Pet slots are spells or pet actions.
        for i=1,C_SpellBook.HasPetSpells() or 0,1 do
            local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Pet)
            if info and info.name == spellName then
                return i;
            end
        end
    end,
})

LibUSC:RegisterParameter("Convert Text to Frame", {
	version = 1,
	type = "Frame",
	category = CATEGORY,
	description = "Converts text (e.g. 'PlayerFrame' or 'ChatFrame1') into the corresponding frame",
	configString = "Frame: {1}",
	
	ParameterTypes = {
		"Text",
	},
	
	Call = function(self)
		local gValue = _G[self.Parameters[1]:GetValue()]
		return type(gValue) == "table" and type(gValue.IsObjectType) == "function" and gValue:IsObjectType("Region") and gValue or nil
	end,
})