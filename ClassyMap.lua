local _, ns = ...
local ClassyMap = LibStub("AceAddon-3.0"):NewAddon("ClassyMap", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ClassyMap")
local LSM = LibStub("LibSharedMedia-3.0")
ns.ClassyMap = ClassyMap

-- Core layer for pure logic (combat queue, validation)
local Core = ClassyMapCore

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

-- Capture observable Blizzard state before writing it. Once another owner changes
-- a property, leave that property alone until the next enable cycle.
local unpackValues = unpack
local function Pack(...)
	return { n = select("#", ...), ... }
end
local function Equal(a, b)
	if a.n ~= b.n then
		return false
	end
	for i = 1, a.n do
		if type(a[i]) == "table" and a[i].n then
			if type(b[i]) ~= "table" or not Equal(a[i], b[i]) then
				return false
			end
		elseif a[i] ~= b[i] then
			return false
		end
	end
	return true
end
local getters = {
	SetUseMaskTexture = "GetUseMaskTexture",
	SetParent = "GetParent",
	SetWidth = "GetWidth",
	SetHeight = "GetHeight",
	SetFixedSize = "GetFixedSize",
	SetFrameStrata = "GetFrameStrata",
	SetScale = "GetScale",
	SetAlpha = "GetAlpha",
	SetFont = "GetFont",
	SetTextColor = "GetTextColor",
	SetTexture = "GetTexture",
	SetJustifyH = "GetJustifyH",
	SetJustifyV = "GetJustifyV",
	SetWordWrap = "CanWordWrap",
	SetClampedToScreen = "IsClampedToScreen",
	SetClampRectInsets = "GetClampRectInsets",
}
local function ReadProperty(frame, key)
	if key == "points" then
		if not frame.GetNumPoints or not frame.GetPoint then
			return nil
		end
		local points = { n = frame:GetNumPoints() }
		for i = 1, points.n do
			points[i] = Pack(frame:GetPoint(i))
		end
		return points
	elseif key == "shown" then
		return frame.IsShown and Pack(frame:IsShown())
	end
	local getter = getters[key]
	return getter and frame[getter] and Pack(frame[getter](frame))
end
function ClassyMap:OwnSet(frame, method, ...)
	if not frame then
		return
	end
	local key = (method == "ClearAllPoints" or method == "SetPoint" or method == "SetAllPoints") and "points"
		or (method == "Show" or method == "Hide") and "shown"
		or method
	self.ownedFrames = self.ownedFrames or {}
	self.frameOriginals = self.frameOriginals or {}
	if not self.frameOriginals[frame] then
		-- Capture geometry before parenting/anchoring changes can alter derived
		-- dimensions; only properties actually written are restored later.
		self.frameOriginals[frame] = {
			points = ReadProperty(frame, "points"),
			SetParent = ReadProperty(frame, "SetParent"),
			SetWidth = ReadProperty(frame, "SetWidth"),
			SetHeight = ReadProperty(frame, "SetHeight"),
		}
	end
	local properties = self.ownedFrames[frame] or {}
	self.ownedFrames[frame] = properties
	local current = ReadProperty(frame, key)
	local state = properties[key]
	if state then
		if state.released then
			return
		end
		if current and not Equal(current, state.last) then
			state.released = true
			return
		end
	elseif current then
		local geometry = key == "points" or key == "SetParent" or key == "SetWidth" or key == "SetHeight"
		state = { original = geometry and self.frameOriginals[frame][key] or current, last = current }
		properties[key] = state
	end
	if state and HybridMinimap and (frame == HybridMinimap.CircleMask or frame == HybridMinimap.MapCanvas) then
		-- Hybrid and base masks must continue to agree with square shape reporting
		-- until reload; base mask state cannot be restored from an API getter.
		state.keepOnDisable = key == "SetTexture" or key == "SetUseMaskTexture"
	end
	-- Remember which other properties still belong to us before this mutation.
	local retained = {}
	for otherKey, otherState in pairs(properties) do
		local value = ReadProperty(frame, otherKey)
		if not otherState.released and otherState.last and value and Equal(value, otherState.last) then
			retained[otherKey] = true
		end
	end
	frame[method](frame, ...)
	if state then
		state.last = ReadProperty(frame, key)
	end
	for otherKey in pairs(retained) do
		properties[otherKey].last = ReadProperty(frame, otherKey)
	end
end
local restoreOrder = {
	"SetParent",
	"SetScale",
	"SetFixedSize",
	"SetWidth",
	"SetHeight",
	"points",
	"SetFrameStrata",
	"SetClampedToScreen",
	"SetClampRectInsets",
	"SetFont",
	"SetJustifyH",
	"SetJustifyV",
	"SetWordWrap",
	"SetTextColor",
	"SetTexture",
	"SetUseMaskTexture",
	"SetAlpha",
	"shown",
}
function ClassyMap:RestoreOwnedFrames()
	-- Decide ownership before restoring anything: a parent/anchor restoration can
	-- itself change derived dimensions on a different frame.
	local eligible = {}
	for frame, properties in pairs(self.ownedFrames or {}) do
		eligible[frame] = {}
		for key, state in pairs(properties) do
			local current = ReadProperty(frame, key)
			eligible[frame][key] = not state.released
				and not state.keepOnDisable
				and current
				and Equal(current, state.last)
		end
	end
	for _, key in ipairs(restoreOrder) do
		for frame, properties in pairs(self.ownedFrames or {}) do
			local state = properties[key]
			if state and eligible[frame][key] then
				local values = state.original
				if key == "points" then
					frame:ClearAllPoints()
					for i = 1, values.n do
						frame:SetPoint(unpackValues(values[i], 1, values[i].n))
					end
				elseif key == "shown" then
					if values[1] then
						frame:Show()
					else
						frame:Hide()
					end
				else
					frame[key](frame, unpackValues(values, 1, values.n))
				end
			end
		end
	end
	self.ownedFrames = nil
	self.frameOriginals = nil
	self.zoomParentIn = nil
	self.zoomParentOut = nil
	self.zoneColorOverridden = nil
	-- Mask and blob APIs expose no matching getters. Keep square shape reporting
	-- consistent with the remaining square mask; a reload fully removes these.
	for _, texture in pairs(self.borders or {}) do
		texture:Hide()
	end
	if self.expansionReplacementBtn then
		self.expansionReplacementBtn:Hide()
	end
	self.restorePending = nil
end

-- Native color/visibility updates are expected while we own their policy.
-- Refresh the comparison baseline only from the corresponding Blizzard hook.
function ClassyMap:AcceptNativeUpdate(frame, key)
	local properties = self.ownedFrames and self.ownedFrames[frame]
	local state = properties and properties[key]
	if state and not state.released then
		local value = ReadProperty(frame, key)
		if value then
			state.last = value
			state.original = value
		end
		return true
	end
end

function ClassyMap:OwnsProperty(frame, key)
	local properties = self.ownedFrames and self.ownedFrames[frame]
	local state = properties and properties[key]
	local current = state and ReadProperty(frame, key)
	if state and not state.released and current and Equal(current, state.last) then
		return true
	end
	if state then
		state.released = true
	end
	return false
end

-- =============================================================================
-- Default Configuration
-- =============================================================================
local defaults = {
	profile = {
		borderColor = { r = 0, g = 0, b = 0, a = 1 },
		borderSize = 1,

		hideZoomButtons = false,
		hideExpansionButton = false,
		expansionIcon = "Interface\\AddOns\\ClassyMap\\Assets\\icon-expansion.tga",
		hideClock = false,

		-- Fonts
		font = "Friz Quadrata TT",
		zoneFontSize = 11,
		overrideZoneColor = false,
		zoneTextColor = { r = 1, g = 1, b = 1, a = 1 },
		clockFontSize = 11,
		clockTextColor = { r = 1, g = 0.82, b = 0, a = 1 }, -- WoW Gold/Yellow

		-- Toggles
		hideCalendar = false,
		hideAddonBtn = false,
		hideTracking = false,
		hideInstance = false,
		hideZoneText = false,

		-- Debug (Mechanic integration)
		debugMode = false,
	},
}

-- =============================================================================
-- Combat Logic (delegates to Core layer)
-- =============================================================================

function ClassyMap:RunSafe(func, ...)
	if self.runtimeEnabled == false then
		return
	end
	local generation = self.refreshGeneration
	if InCombatLockdown() then
		-- Queue action for when combat ends
		Core:QueueAction(function(...)
			if generation == self.refreshGeneration and self.runtimeEnabled ~= false then
				func(self, ...)
			end
		end, { n = select("#", ...), ... })
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProcessCombatQueue")
	else
		func(self, ...)
	end
end

function ClassyMap:ProcessCombatQueue()
	if InCombatLockdown() then
		return
	end
	if self.restorePending then
		self:RestoreOwnedFrames()
	end
	Core:ProcessQueue(geterrorhandler())
	if self.pendingRefresh then
		self:RequestRefresh(next(self.pendingRefresh))
	end
	if Core:GetQueueLength() == 0 then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	else
		local generation = self.refreshGeneration
		C_Timer.After(0, function()
			if generation == self.refreshGeneration then
				self:ProcessCombatQueue()
			end
		end)
	end
end

-- =============================================================================
-- Initialization
-- =============================================================================
function ClassyMap:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ClassyMapDB", defaults, true)

	self:RegisterChatCommand("classymap", "SlashHandler")
	self:RegisterChatCommand("cm", "SlashHandler")

	if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
		AddonCompartmentFrame:RegisterAddon({
			text = L["ClassyMap"],
			icon = "Interface\\Icons\\INV_Misc_Map02",
			notCheckable = true,
			func = function()
				ns.Settings:OpenOptions()
			end,
		})
	end

	self:Print(L["Loaded. Type /classymap or /cm for options."])
end

function ClassyMap:OnEnable()
	self.runtimeEnabled = true
	self.refreshGeneration = (self.refreshGeneration or 0) + 1
	self.refreshScheduled = nil
	self.restorePending = nil
	if self.restoreFrame then
		self.restoreFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self.worldReady = IsLoggedIn()
	self:RegisterEvent("ADDON_LOADED", "OnBlizzardAddonLoaded")
	if Minimap_Update and not self.hookedZoneColor then
		hooksecurefunc("Minimap_Update", function()
			if self.runtimeEnabled and self:AcceptNativeUpdate(MinimapZoneText, "SetTextColor") then
				self:RequestRefresh("fonts")
			end
		end)
		self.hookedZoneColor = true
	end
	if IsLoggedIn() then
		self:RequestRefresh("all")
	else
		self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
			self.worldReady = true
			self:RequestRefresh("all")
			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end)
	end

	-- Enforce Zone Text Colors on Zone Change
	self:RegisterEvent("ZONE_CHANGED", "ApplyFontStyles")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "ApplyFontStyles")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ApplyFontStyles")
end

function ClassyMap:OnDisable()
	self.runtimeEnabled = false
	self.refreshGeneration = (self.refreshGeneration or 0) + 1
	self.refreshScheduled = nil
	self.pendingRefresh = nil
	Core:ClearQueue()
	self:UnregisterAllEvents()
	if InCombatLockdown() then
		self.restorePending = true
		-- AceEvent unregisters addon events after OnDisable returns. A private frame
		-- owns this one-shot restoration event so it survives that library cleanup.
		if not self.restoreFrame then
			self.restoreFrame = CreateFrame("Frame")
			self.restoreFrame:SetScript("OnEvent", function(frame)
				if not InCombatLockdown() then
					frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
					if self.restorePending and not self.runtimeEnabled then
						self:RestoreOwnedFrames()
					end
				end
			end)
		end
		self.restoreFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:RestoreOwnedFrames()
	end
end

function ClassyMap:RequestRefresh(scope)
	if not self.runtimeEnabled then
		return
	end
	scope = scope or "all"
	if scope == "full" then
		scope = "all"
	end
	assert(
		scope == "all" or scope == "border" or scope == "fonts" or scope == "visibility" or scope == "layout",
		"Unknown refresh scope"
	)
	self.pendingRefresh = self.pendingRefresh or {}
	self.pendingRefresh[scope] = true
	if self.refreshScheduled or not self.worldReady then
		return
	end
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProcessCombatQueue")
		return
	end
	self.refreshScheduled = true
	local generation = self.refreshGeneration
	C_Timer.After(0, function()
		if generation ~= self.refreshGeneration or not self.runtimeEnabled then
			return
		end
		self.refreshScheduled = nil
		if InCombatLockdown() then
			self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProcessCombatQueue")
			return
		end
		local pending = self.pendingRefresh
		self.pendingRefresh = nil
		if not pending then
			return
		end
		self.executingRefresh = true
		local started = debugprofilestop()
		local ok, err = pcall(function()
			if pending.all then
				self:ApplyMinimapChanges()
			else
				if pending.border then
					self:MeasureRefresh("CreateBorder", self.CreateBorder)
				end
				if pending.visibility then
					self:MeasureRefresh("HideClutter", self.HideMinimapClutter)
				end
				if pending.fonts then
					self:MeasureRefresh("ApplyFontStyles", self.ApplyFontStyles)
				end
				if pending.layout or pending.visibility then
					self:MeasureRefresh("FixLayout", self.FixLayout)
				end
			end
		end)
		self.executingRefresh = nil
		if ClassyMapMechanic then
			ClassyMapMechanic:RecordPerfMetric("Refresh", debugprofilestop() - started)
		end
		if not ok then
			geterrorhandler()(err)
		end
	end)
end

function ClassyMap:MeasureRefresh(name, action)
	local started = debugprofilestop()
	local ok, err = pcall(action, self)
	if ClassyMapMechanic then
		ClassyMapMechanic:RecordPerfMetric(name, debugprofilestop() - started)
	end
	if not ok then
		geterrorhandler()(err)
	end
end

function ClassyMap:OnBlizzardAddonLoaded(_, addon)
	if
		addon == "Blizzard_TimeManager"
		or addon == "Blizzard_HybridMinimap"
		or addon == "Blizzard_ExpansionLandingPage"
	then
		self:ApplyMinimapChanges()
	end
end

function ClassyMap:SlashHandler()
	ns.Settings:OpenOptions()
end

-- =============================================================================
-- Core Minimap Modifications
-- =============================================================================
function ClassyMap:SatStyles(f)
	if not f then
		return
	end
	self:OwnSet(f, "SetParent", Minimap)
	self:OwnSet(f, "SetFrameStrata", "DIALOG")
	self:OwnSet(f, "Show")
end

-- The map's rendered size expressed in MinimapCluster coordinates. Edit Mode's
-- "Size" setting scales MinimapContainer, which sits between the two, so the
-- map's own GetWidth() no longer describes the space it occupies in the cluster.
function ClassyMap:GetMinimapFootprint()
	local scale = 1
	local frame = Minimap
	while frame and frame ~= MinimapCluster do
		scale = scale * (frame.GetScale and frame:GetScale() or 1)
		frame = frame.GetParent and frame:GetParent()
	end
	if not frame then
		-- Another addon moved the map out of the cluster; compare effective scales.
		scale = 1
		if Minimap.GetEffectiveScale and MinimapCluster.GetEffectiveScale then
			local clusterScale = MinimapCluster:GetEffectiveScale()
			if clusterScale and clusterScale > 0 then
				scale = Minimap:GetEffectiveScale() / clusterScale
			end
		end
	end
	return Minimap:GetWidth() * scale, Minimap:GetHeight() * scale
end

local function ApplyLayout(self)
	local db = self.db.profile
	local MARGIN = 4
	local STACK_GAP = 2
	local ICON_SIZE = 24 -- Size for standardized placement if needed

	-- Cluster & Map. MinimapCluster is a Blizzard ResizeLayoutFrame: its Layout()
	-- pass (Edit Mode, OnShow) resizes it to the bounding box of the native
	-- children, which is larger than the square map and leaves the Edit Mode
	-- selection box loose around it. A fixed size makes Layout() reproduce the
	-- map's footprint instead, so the selection box and screen clamping match
	-- the map exactly.
	if MinimapCluster and Minimap then
		local width, height = self:GetMinimapFootprint()
		if MinimapCluster.SetFixedSize then
			self:OwnSet(MinimapCluster, "SetFixedSize", width, height)
		end
		self:OwnSet(MinimapCluster, "SetWidth", width)
		self:OwnSet(MinimapCluster, "SetHeight", height)
	end
	if Minimap then
		self:OwnSet(Minimap, "ClearAllPoints")
		self:OwnSet(Minimap, "SetPoint", "CENTER", MinimapCluster, "CENTER", 0, 0)
	end

	-- Zone Text (Top Center)
	if MinimapCluster.ZoneTextButton then
		if not db.hideZoneText then
			self:SatStyles(MinimapCluster.ZoneTextButton)
			self:OwnSet(MinimapCluster.ZoneTextButton, "ClearAllPoints")
			-- Header Row Alignment (User Tweak: Down 2px from +2 -> 0)
			self:OwnSet(MinimapCluster.ZoneTextButton, "SetPoint", "TOP", Minimap, "TOP", 0, 0)
			self:OwnSet(MinimapCluster.ZoneTextButton, "SetHeight", ICON_SIZE) -- Match Icon Height (24)
			self:OwnSet(MinimapCluster.ZoneTextButton, "SetAlpha", 1)

			-- Centering Text
			if MinimapZoneText then
				self:OwnSet(MinimapZoneText, "ClearAllPoints")
				self:OwnSet(MinimapZoneText, "SetAllPoints", MinimapCluster.ZoneTextButton)
				self:OwnSet(MinimapZoneText, "SetJustifyH", "CENTER")
				self:OwnSet(MinimapZoneText, "SetJustifyV", "MIDDLE")
				self:OwnSet(MinimapZoneText, "SetWordWrap", false)
			end
		else
			self:OwnSet(MinimapCluster.ZoneTextButton, "Hide")
		end
	end

	-- Clock (Below Zone Text)
	if TimeManagerClockButton then
		if not db.hideClock then
			self:SatStyles(TimeManagerClockButton)
			self:OwnSet(TimeManagerClockButton, "ClearAllPoints")
			if MinimapCluster.ZoneTextButton and not db.hideZoneText then
				self:OwnSet(TimeManagerClockButton, "SetPoint", "TOP", MinimapCluster.ZoneTextButton, "BOTTOM", 0, 0)
			else
				self:OwnSet(TimeManagerClockButton, "SetPoint", "TOP", Minimap, "TOP", 0, -MARGIN)
			end
		else
			self:OwnSet(TimeManagerClockButton, "Hide")
		end
	end

	-- Tracking (TOP LEFT)
	-- Native Tracking frame is quirky, but let's try standard anchor
	if MinimapCluster.Tracking then
		if not db.hideTracking then
			self:SatStyles(MinimapCluster.Tracking)
			self:OwnSet(MinimapCluster.Tracking, "ClearAllPoints")
			self:OwnSet(MinimapCluster.Tracking, "SetPoint", "TOPLEFT", Minimap, "TOPLEFT", MARGIN, -MARGIN)
		else
			self:OwnSet(MinimapCluster.Tracking, "Hide")
		end
	end

	-- Stack Logic (TOP RIGHT)
	local lastFrame = nil

	-- Calendar
	if GameTimeFrame then
		if not db.hideCalendar then
			self:SatStyles(GameTimeFrame)
			self:OwnSet(GameTimeFrame, "ClearAllPoints")
			self:OwnSet(GameTimeFrame, "SetPoint", "TOPRIGHT", Minimap, "TOPRIGHT", -MARGIN, -MARGIN)
			self:OwnSet(GameTimeFrame, "SetScale", 1.0)
			lastFrame = GameTimeFrame
		else
			self:OwnSet(GameTimeFrame, "Hide")
		end
	end

	-- Addon Drawer
	if AddonCompartmentFrame then
		if not db.hideAddonBtn then
			self:SatStyles(AddonCompartmentFrame)
			self:OwnSet(AddonCompartmentFrame, "ClearAllPoints")
			if lastFrame then
				-- Center align with manual tweak (User requested revert to previous -> -2)
				self:OwnSet(AddonCompartmentFrame, "SetPoint", "TOP", lastFrame, "BOTTOM", -2, -STACK_GAP)
			else
				self:OwnSet(AddonCompartmentFrame, "SetPoint", "TOPRIGHT", Minimap, "TOPRIGHT", -MARGIN, -MARGIN)
			end
			self:OwnSet(AddonCompartmentFrame, "SetScale", 1.0)
		else
			self:OwnSet(AddonCompartmentFrame, "Hide")
		end
	end

	-- Instance Difficulty (Left of Top Item)
	local diffFrame = MinimapCluster.InstanceDifficulty
	if diffFrame then
		if not db.hideInstance then
			self:SatStyles(diffFrame)
			self:OwnSet(diffFrame, "ClearAllPoints")
			local topFrame = nil
			if GameTimeFrame and GameTimeFrame:IsShown() then
				topFrame = GameTimeFrame
			elseif AddonCompartmentFrame and AddonCompartmentFrame:IsShown() then
				topFrame = AddonCompartmentFrame
			end

			if topFrame then
				self:OwnSet(diffFrame, "SetPoint", "RIGHT", topFrame, "LEFT", -STACK_GAP, 0)
			else
				self:OwnSet(diffFrame, "SetPoint", "TOPRIGHT", Minimap, "TOPRIGHT", -MARGIN, -MARGIN)
			end
			self:OwnSet(diffFrame, "SetScale", 1.0)
		else
			self:OwnSet(diffFrame, "Hide")
		end
	end

	-- Expansion Button (BOTTOM LEFT)
	local expBtn = _G["ClassyMapExpansionBtn"]
	if expBtn then
		if not db.hideExpansionButton then
			self:SatStyles(expBtn)
			expBtn:ClearAllPoints()
			expBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", MARGIN, MARGIN)
			expBtn:SetScale(1.0)
		else
			expBtn:Hide()
		end
	end
end

function ClassyMap:RequestLayout()
	if not self.resizing then
		self:RequestRefresh("layout")
	end
end

function ClassyMap:FixLayout()
	if not self.executingRefresh then
		self:RequestRefresh("layout")
		return
	end
	if InCombatLockdown() then
		self:RequestLayout()
		return
	end
	if self.resizing then
		return
	end
	self.resizing = true
	local ok, err = pcall(ApplyLayout, self)
	self.resizing = nil
	if not ok then
		geterrorhandler()(err)
	end
end

function ClassyMap:ApplyMinimapChanges()
	if not self.executingRefresh then
		self:RequestRefresh("all")
		return
	end
	self:MeasureRefresh("Setup", function()
		-- Relinquish mask changes together with shape reporting if another addon takes over.
		if not self.shapeOverride or GetMinimapShape == self.shapeOverride then
			-- Mask/blob scalar APIs have no observable original state; reload restores them.
			Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
			if HybridMinimap then
				self:OwnSet(HybridMinimap.MapCanvas, "SetUseMaskTexture", false)
				self:OwnSet(HybridMinimap.CircleMask, "SetTexture", "Interface\\BUTTONS\\WHITE8X8")
				self:OwnSet(HybridMinimap.MapCanvas, "SetUseMaskTexture", true)
			end
			Minimap:SetArchBlobRingScalar(0)
			Minimap:SetArchBlobRingAlpha(0)
			Minimap:SetQuestBlobRingScalar(0)
			Minimap:SetQuestBlobRingAlpha(0)
			Minimap:SetTaskBlobRingScalar(0)
			Minimap:SetTaskBlobRingAlpha(0)
			if not self.shapeOverride then
				self.shapeOverride = function()
					return "SQUARE"
				end
				GetMinimapShape = self.shapeOverride
			end
		end
		if MinimapCluster then
			self:OwnSet(MinimapCluster, "SetClampedToScreen", true)
			-- The cluster now matches the map, so it can sit flush against the screen edge.
			self:OwnSet(MinimapCluster, "SetClampRectInsets", 0, 0, 0, 0)
		end
		self:OwnSet(Minimap, "SetClampedToScreen", false)
	end)
	self:MeasureRefresh("CreateBorder", self.CreateBorder)
	self:MeasureRefresh("HideClutter", self.HideMinimapClutter)
	self:MeasureRefresh("ApplyFontStyles", self.ApplyFontStyles)
	self:MeasureRefresh("FixLayout", self.FixLayout)

	if not self.hookedLayout then
		hooksecurefunc(MinimapCluster, "SetWidth", function()
			self:RequestLayout()
		end)
		hooksecurefunc(MinimapCluster, "SetHeight", function()
			self:RequestLayout()
		end)
		if MinimapCluster.SetEditModeScale then
			-- Edit Mode "Size" scales MinimapContainer; the fixed cluster size must follow.
			hooksecurefunc(MinimapCluster, "SetEditModeScale", function()
				self:RequestLayout()
			end)
		end
		if MinimapCluster.Layout then
			-- Safety net: a native layout pass that lands on a different size (stale
			-- fixed size, or another addon cleared it) gets one corrective pass.
			hooksecurefunc(MinimapCluster, "Layout", function(cluster)
				if not self.runtimeEnabled or self.resizing then
					return
				end
				local width, height = self:GetMinimapFootprint()
				if cluster:GetWidth() ~= width or cluster:GetHeight() ~= height then
					self:RequestLayout()
				end
			end)
		end
		self.hookedLayout = true
	end
end

function ClassyMap:CreateBorder()
	if self.borders then
		self:UpdateBorderStyle()
		return
	end

	-- Textures on the map keep the border below child frames and buttons.

	self.borders = {}
	local function CreateLine()
		-- Create texture on Minimap.
		-- ARTWORK layer ensures it is visible above the map terrain (BACKGROUND),
		-- But as a texture on the Frame, it is strictly below any Child Frames (Buttons).
		local t = Minimap:CreateTexture(nil, "ARTWORK")
		t:SetTexture("Interface\\BUTTONS\\WHITE8X8")
		return t
	end

	self.borders.top = CreateLine()
	self.borders.bottom = CreateLine()
	self.borders.left = CreateLine()
	self.borders.right = CreateLine()

	-- Remove old frame if it exists from previous load
	if self.borderFrame then
		self.borderFrame:Hide()
		self.borderFrame = nil
	end

	self:UpdateBorderStyle()
end

function ClassyMap:UpdateBorderStyle()
	if not self.borders then
		return
	end

	-- Use Core layer for validation
	local size = Core:ValidateBorderSize(self.db.profile.borderSize)
	local c = Core:ValidateColor(self.db.profile.borderColor)

	-- If size is 0, hide all
	if size <= 0 then
		for _, tex in pairs(self.borders) do
			tex:Hide()
		end
		return
	end

	-- Setup textures
	for _, tex in pairs(self.borders) do
		tex:SetVertexColor(c.r, c.g, c.b, c.a)
		tex:Show()
		tex:ClearAllPoints()
	end

	-- Top (Spans full width)
	self.borders.top:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
	self.borders.top:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
	self.borders.top:SetHeight(size)

	-- Bottom (Spans full width)
	self.borders.bottom:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
	self.borders.bottom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
	self.borders.bottom:SetHeight(size)

	-- Left (Spans top to bottom)
	self.borders.left:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
	self.borders.left:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
	self.borders.left:SetWidth(size)

	-- Right (Spans top to bottom)
	self.borders.right:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
	self.borders.right:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
	self.borders.right:SetWidth(size)
end

function ClassyMap:HideMinimapClutter()
	local db = self.db.profile

	-- Force Hide Compass
	if MinimapCompassTexture then
		self:OwnSet(MinimapCompassTexture, "Hide")
		self:OwnSet(MinimapCompassTexture, "SetAlpha", 0)
	end

	-- Zoom Buttons
	if db.hideZoomButtons then
		if not self.zoomParentIn then
			self.zoomParentIn = Minimap.ZoomIn:GetParent()
		end
		if not self.zoomParentOut then
			self.zoomParentOut = Minimap.ZoomOut:GetParent()
		end
		self:OwnSet(Minimap.ZoomIn, "SetParent", hiddenFrame)
		self:OwnSet(Minimap.ZoomOut, "SetParent", hiddenFrame)
	else
		if self.zoomParentIn then
			self:OwnSet(Minimap.ZoomIn, "SetParent", self.zoomParentIn)
		end
		if self.zoomParentOut then
			self:OwnSet(Minimap.ZoomOut, "SetParent", self.zoomParentOut)
		end
	end

	-- Expansion Landing Page (Always Replace Native)
	if ExpansionLandingPageMinimapButton then
		self:OwnSet(ExpansionLandingPageMinimapButton, "Hide")
		self:OwnSet(ExpansionLandingPageMinimapButton, "SetAlpha", 0)
		if not self.expHooked then
			hooksecurefunc(ExpansionLandingPageMinimapButton, "Show", function(button)
				if self.runtimeEnabled and self:AcceptNativeUpdate(button, "shown") then
					self:RequestRefresh("visibility")
				end
			end)
			self.expHooked = true
		end
	end

	self:CreateExpansionReplacement()

	-- Custom Button Visibility
	if self.expansionReplacementBtn then
		if db.hideExpansionButton then
			self.expansionReplacementBtn:Hide()
		else
			self.expansionReplacementBtn:Show()
		end
	end

	-- Tracking
	if MinimapCluster.Tracking then
		if db.hideTracking then
			self:OwnSet(MinimapCluster.Tracking, "Hide")
		else
			self:OwnSet(MinimapCluster.Tracking, "Show")
		end
	end

	-- BorderTop
	if MinimapCluster.BorderTop then
		self:OwnSet(MinimapCluster.BorderTop, "Hide")
		self:OwnSet(MinimapCluster.BorderTop, "SetAlpha", 0)
	end
end

-- Newest-first list of expansion landing-button atlases. Used as a fallback
-- chain when an expansion (e.g. Midnight in beta) hasn't shipped its own art.
local EXPANSION_ICON_ATLASES = {
	"midnight-landingbutton-up",
	"warwithin-landingbutton-up",
	"dragonflight-landingbutton-up",
}

function ClassyMap:GetExpansionIconAtlas()
	-- Prefer whatever the live ExpansionLandingPage system reports — matches
	-- Blizzard's own button when that subsystem is loaded.
	if ExpansionLandingPage and ExpansionLandingPage.GetOverlayMinimapDisplayInfo then
		local ok, info = pcall(ExpansionLandingPage.GetOverlayMinimapDisplayInfo, ExpansionLandingPage)
		if ok and info and info.normalAtlas and C_Texture.GetAtlasInfo(info.normalAtlas) then
			return info.normalAtlas
		end
	end

	for _, atlas in ipairs(EXPANSION_ICON_ATLASES) do
		if C_Texture.GetAtlasInfo(atlas) then
			return atlas
		end
	end
end

function ClassyMap:ApplyExpansionIcon(icon)
	if not icon then
		return
	end
	local atlas = self:GetExpansionIconAtlas()
	if atlas then
		icon:SetAtlas(atlas, false)
		return
	end
	local iconPath = self.db.profile.expansionIcon
	if not iconPath or iconPath == "" then
		iconPath = "Interface\\Icons\\Inv_misc_book_17"
	end
	icon:SetTexture(iconPath)
	icon:SetTexCoord(0, 1, 0, 1)
end

function ClassyMap:CreateExpansionReplacement()
	if self.expansionReplacementBtn then
		self:ApplyExpansionIcon(self.expansionReplacementBtn.icon)
		return
	end

	local btn = CreateFrame("Button", "ClassyMapExpansionBtn", MinimapCluster)
	btn:SetSize(24, 24) -- Resized to match standard small buttons
	btn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
	btn:SetFrameStrata("DIALOG")
	btn:SetFrameLevel(100)

	btn.icon = btn:CreateTexture(nil, "ARTWORK")
	btn.icon:SetAllPoints()

	self:ApplyExpansionIcon(btn.icon)

	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	btn:SetScript("OnClick", function()
		-- Open the Adventure Guide (shift-J): renown, traveler's log, dungeons,
		-- raids — the panel that actually summarizes current-expansion progress.
		-- The native ExpansionLandingPageMinimapButton opens the most recently
		-- unlocked covenant/garrison instead, which is rarely what we want.
		if ToggleEncounterJournal then
			pcall(ToggleEncounterJournal)
		end
	end)

	btn:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_LEFT")
		GameTooltip:AddLine(L["Expansion Summary"])
		GameTooltip:AddLine(L["Click to open expansion summary"], 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self.expansionReplacementBtn = btn
end

function ClassyMap:ApplyZoneColor()
	if not self.runtimeEnabled then
		return
	end
	if MinimapZoneText and self.db.profile.overrideZoneColor then
		local c = Core:ValidateColor(self.db.profile.zoneTextColor)
		self:OwnSet(MinimapZoneText, "SetTextColor", c.r, c.g, c.b, c.a)
		self.zoneColorOverridden = true
	end
end

function ClassyMap:ApplyFontStyles()
	if not self.executingRefresh then
		self:RequestRefresh("fonts")
		return
	end
	local db = self.db.profile
	local fontPath = LSM:Fetch("font", db.font) or "Fonts\\FRIZQT__.TTF"

	if MinimapZoneText then
		-- Use Core layer for validation
		local zoneFontSize = Core:ValidateFontSize(db.zoneFontSize)
		self:OwnSet(MinimapZoneText, "SetFont", fontPath, zoneFontSize, "OUTLINE")

		self:ApplyZoneColor()
		if not db.overrideZoneColor and self.zoneColorOverridden and Minimap_Update then
			self.zoneColorOverridden = nil
			if self:OwnsProperty(MinimapZoneText, "SetTextColor") then
				Minimap_Update()
				self.ownedFrames[MinimapZoneText].SetTextColor = nil
			end
		end
	end

	if TimeManagerClockButton then
		local region = TimeManagerClockTicker
		if region and region.SetFont then
			-- Use Core layer for validation
			local clockFontSize = Core:ValidateFontSize(db.clockFontSize)
			local c = Core:ValidateColor(db.clockTextColor)
			self:OwnSet(region, "SetFont", fontPath, clockFontSize, "OUTLINE")
			self:OwnSet(region, "SetTextColor", c.r, c.g, c.b, c.a)
		end
	end
end
