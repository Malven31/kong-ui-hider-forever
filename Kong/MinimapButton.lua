-- Forever port: a minimap button showing the addon's logo. Left-click opens or closes the settings
-- window (like /kong), right-click turns fading on and off (like /kong toggle), and dragging moves the
-- button around the minimap. Kong_Minimap (saved for the whole account) keeps its position and whether
-- it is hidden; /kong minimap hides or shows it.
local N, A = ...

local ICON = "Interface\\AddOns\\Kong\\media\\minimap"
local DEFAULT_ANGLE = 225 -- degrees counter-clockwise from the right: the bottom left of the minimap
local EDGE_OFFSET = 5 -- how far outside the minimap's edge the button's centre sits
local DEFAULT_MINIMAP_RADIUS = 70

local issecretvalue = issecretvalue or function() return false end

-- For each minimap shape (GetMinimapShape, defined by minimap addons such as SexyMap): whether each
-- quadrant is rounded. Quadrants: 1 bottom right, 2 bottom left, 3 top right, 4 top left.
local MINIMAP_SHAPES = {
	["ROUND"] = {true, true, true, true},
	["SQUARE"] = {false, false, false, false},
	["CORNER-TOPLEFT"] = {false, false, false, true},
	["CORNER-TOPRIGHT"] = {false, false, true, false},
	["CORNER-BOTTOMLEFT"] = {false, true, false, false},
	["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
	["SIDE-LEFT"] = {false, true, false, true},
	["SIDE-RIGHT"] = {true, false, true, false},
	["SIDE-TOP"] = {false, false, true, true},
	["SIDE-BOTTOM"] = {true, true, false, false},
	["TRICORNER-TOPLEFT"] = {false, true, true, true},
	["TRICORNER-TOPRIGHT"] = {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

local button

local function GetHalfSize(getter)
	local size = getter(Minimap)
	if ( issecretvalue(size) or type(size) ~= "number" or size <= 0 ) then
		return DEFAULT_MINIMAP_RADIUS + EDGE_OFFSET
	end
	return size / 2 + EDGE_OFFSET
end

local function UpdatePosition()
	local angle = math.rad(Kong_Minimap.angle)
	local x, y = math.cos(angle), math.sin(angle)
	local quadrant = 1
	if ( x < 0 ) then quadrant = quadrant + 1 end
	if ( y > 0 ) then quadrant = quadrant + 2 end

	local shape = type(GetMinimapShape) == "function" and GetMinimapShape() or "ROUND"
	local rounded = (MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"])[quadrant]
	local w = GetHalfSize(Minimap.GetWidth)
	local h = GetHalfSize(Minimap.GetHeight)
	if ( rounded ) then
		x, y = x * w, y * h
	else
		-- A square corner: go out along the diagonal, then stay on the minimap's edge.
		local diagonalW = math.sqrt(2 * w * w) - 10
		local diagonalH = math.sqrt(2 * h * h) - 10
		x = math.max(-w, math.min(x * diagonalW, w))
		y = math.max(-h, math.min(y * diagonalH, h))
	end

	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate()
	local mx, my = Minimap:GetCenter()
	local cx, cy = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	if ( mx == nil or my == nil or cx == nil or cy == nil or scale == nil ) then return end
	if ( issecretvalue(mx) or issecretvalue(my) or issecretvalue(cx) or issecretvalue(cy) or issecretvalue(scale) ) then return end
	if ( scale <= 0 ) then return end
	Kong_Minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
	UpdatePosition()
end

local function IsConfigShown()
	return KongConfig ~= nil and KongConfig.frame ~= nil and KongConfig.frame:IsShown()
end

local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine("Kong UI Hider - Forever")
	if ( Kong_Settings ~= nil and Kong_Settings.enabled ) then
		GameTooltip:AddLine("Fading is on.", 1, 1, 1)
	else
		GameTooltip:AddLine("Fading is off.", 1, 1, 1)
	end
	GameTooltip:AddLine(IsConfigShown() and "Left-click: close the settings" or "Left-click: open the settings", 0.2, 1, 0.6)
	GameTooltip:AddLine("Right-click: turn fading on or off", 0.2, 1, 0.6)
	GameTooltip:AddLine("Drag: move this button", 0.2, 1, 0.6)
	GameTooltip:AddLine("/kong minimap: hide this button", 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

local function OnClick(self, mouseButton)
	if ( mouseButton == "RightButton" ) then
		A.CommandHandler("toggle") -- refuses while the settings window is open, as /kong toggle does
	elseif ( IsConfigShown() ) then
		KongConfig.frame:Hide() -- runs the window's own close handler, which fades the frames again
	else
		A.CommandHandler("")
	end
	if ( GameTooltip:GetOwner() == self ) then
		ShowTooltip(self)
	end
end

local function CreateButton()
	local b = CreateFrame("Button", "KongUIHiderMinimapButton", Minimap)
	b:SetFrameStrata("MEDIUM")
	if ( b.SetFixedFrameStrata ) then b:SetFixedFrameStrata(true) end
	b:SetFrameLevel(8)
	if ( b.SetFixedFrameLevel ) then b:SetFixedFrameLevel(true) end
	b:SetSize(31, 31)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = b:CreateTexture(nil, "BACKGROUND")
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetSize(20, 20)
	background:SetPoint("TOPLEFT", 7, -5)

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ICON)
	icon:SetSize(17, 17)
	icon:SetPoint("TOPLEFT", 7, -6)

	local border = b:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")

	b:SetScript("OnClick", OnClick)
	b:SetScript("OnEnter", ShowTooltip)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	b:SetScript("OnDragStart", function(self)
		GameTooltip:Hide()
		self:LockHighlight()
		self:SetScript("OnUpdate", OnDragUpdate)
	end)
	b:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		self:UnlockHighlight()
	end)

	-- Some minimap addons resize the minimap: follow its edge.
	Minimap:HookScript("OnSizeChanged", function()
		if ( button ~= nil and button:IsShown() ) then UpdatePosition() end
	end)
	return b
end

function A.UpdateMinimapButton()
	if ( Kong_Minimap.hide ) then
		if ( button ~= nil ) then button:Hide() end
		return
	end
	button = button or CreateButton()
	UpdatePosition()
	button:Show()
end

function A.ToggleMinimapButton()
	Kong_Minimap.hide = not Kong_Minimap.hide
	A.UpdateMinimapButton()
	if ( Kong_Minimap.hide ) then
		Kong_Info("Minimap button hidden. Type |cFF33FF99/kong minimap|r to show it again.")
	else
		Kong_Info("Minimap button shown.")
	end
end

-- Saved values are data from a file the player can edit: keep only what has the expected type.
local function LoadSavedSettings()
	if ( type(Kong_Minimap) ~= "table" ) then
		Kong_Minimap = {}
	end
	local angle = tonumber(Kong_Minimap.angle)
	if ( angle == nil or angle ~= angle or angle == math.huge or angle == -math.huge ) then
		angle = DEFAULT_ANGLE
	end
	Kong_Minimap.angle = angle % 360
	Kong_Minimap.hide = (Kong_Minimap.hide == true)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	if ( Minimap == nil ) then return end
	LoadSavedSettings()
	A.UpdateMinimapButton()
end)
