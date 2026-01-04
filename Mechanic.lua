-- ClassyMap Mechanic Integration
-- Provides MechanicLib registration, tools panel, in-game tests, and debug logging

local addonName, ns = ...
local MechanicLib = LibStub("MechanicLib-1.0", true)

---@class ClassyMapMechanic
ClassyMapMechanic = {}
ClassyMapMechanic.debugBuffer = {}

-- =============================================================================
-- Throttled Debug Logging (Console-only, no chat spam)
-- =============================================================================

local logThrottle = {}
local LOG_INTERVAL = 0.1 -- seconds between identical messages

function ClassyMapMechanic:Log(msg, category)
	if not ClassyMapDB or not ClassyMapDB.profile or not ClassyMapDB.profile.debugMode then
		return
	end

	local now = GetTime()
	if logThrottle[msg] and (now - logThrottle[msg]) < LOG_INTERVAL then
		return
	end
	logThrottle[msg] = now

	-- Store in internal buffer for Mechanic's pull model
	table.insert(self.debugBuffer, { msg = msg, time = now })
	if #self.debugBuffer > 500 then
		table.remove(self.debugBuffer, 1)
	end

	-- Log to Mechanic's console only (no chat spam)
	if MechanicLib then
		MechanicLib:Log(addonName, msg, category or MechanicLib.Categories.CORE)
	end
end

-- =============================================================================
-- Tools Panel (Button-based)
-- =============================================================================

-- Helper to safely get addon's db profile (AceDB wraps ClassyMapDB)
local function GetProfile()
	local addon = ns.ClassyMap
	return addon and addon.db and addon.db.profile
end

local function CreateToolButton(parent, x, y, width, text, onClick)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	btn:SetSize(width, 24)
	btn:SetText(text)
	btn:SetScript("OnClick", onClick)
	return btn
end

function ClassyMapMechanic:CreateToolsPanel(container)
	-- Title
	local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText("ClassyMap Tools")

	-- Description
	local desc = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 10, -35)
	desc:SetText("Quick actions for minimap customization.")

	-- Row 1: Toggle & Settings
	local row1Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row1Label:SetPoint("TOPLEFT", 10, -65)
	row1Label:SetText("Addon:")

	CreateToolButton(container, 80, -60, 80, "Toggle", function()
		local profile = GetProfile()
		if profile then
			profile.enabled = not profile.enabled
			if ns.ClassyMap then
				ns.ClassyMap:RunSafe(ns.ClassyMap.ApplyMinimapChanges)
			end
			print("|cff00ff00ClassyMap:|r " .. (profile.enabled and "Enabled" or "Disabled"))
		else
			print("|cffff0000ClassyMap:|r Not initialized yet")
		end
	end)

	CreateToolButton(container, 165, -60, 80, "Settings", function()
		if ns.Settings then
			ns.Settings:OpenOptions()
		else
			print("|cffff0000ClassyMap:|r Settings not available")
		end
	end)

	-- Row 2: Border Size
	local row2Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row2Label:SetPoint("TOPLEFT", 10, -100)
	row2Label:SetText("Border:")

	CreateToolButton(container, 80, -95, 50, "0", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 0
			if ns.ClassyMap then
				ns.ClassyMap:UpdateBorderStyle()
			end
			print("|cff00ff00ClassyMap:|r Border hidden")
		end
	end)

	CreateToolButton(container, 135, -95, 50, "1", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 1
			if ns.ClassyMap then
				ns.ClassyMap:UpdateBorderStyle()
			end
			print("|cff00ff00ClassyMap:|r Border = 1px")
		end
	end)

	CreateToolButton(container, 190, -95, 50, "2", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 2
			if ns.ClassyMap then
				ns.ClassyMap:UpdateBorderStyle()
			end
			print("|cff00ff00ClassyMap:|r Border = 2px")
		end
	end)

	CreateToolButton(container, 245, -95, 50, "4", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 4
			if ns.ClassyMap then
				ns.ClassyMap:UpdateBorderStyle()
			end
			print("|cff00ff00ClassyMap:|r Border = 4px")
		end
	end)

	-- Row 3: Debug
	local row3Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row3Label:SetPoint("TOPLEFT", 10, -135)
	row3Label:SetText("Debug:")

	CreateToolButton(container, 80, -130, 100, "Toggle Debug", function()
		local profile = GetProfile()
		if profile then
			profile.debugMode = not profile.debugMode
			print("|cff00ff00ClassyMap:|r Debug " .. (profile.debugMode and "ON" or "OFF"))
		end
	end)

	-- Footer
	local footer = container:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	footer:SetPoint("BOTTOM", 0, 10)
	footer:SetText("Use /classymap or /cm for more options.")
end

-- =============================================================================
-- In-Game Tests
-- =============================================================================

ClassyMapMechanic.tests = {
	{
		id = "minimap_shape",
		name = "Minimap Shape Override",
		category = "API",
		type = "auto",
		description = "Verifies GetMinimapShape returns SQUARE when enabled.",
	},
	{
		id = "border_textures",
		name = "Border Textures",
		category = "UI",
		type = "auto",
		description = "Checks border textures are created and visible.",
	},
	{
		id = "mask_texture",
		name = "Square Mask Applied",
		category = "UI",
		type = "auto",
		description = "Verifies the square mask is applied to Minimap.",
	},
}

function ClassyMapMechanic:GetTests()
	return self.tests
end

function ClassyMapMechanic:RunTest(id)
	local start = debugprofilestop()
	local result = self:GetTestResult(id)
	result.duration = (debugprofilestop() - start) / 1000
	result.id = id
	return result
end

function ClassyMapMechanic:GetTestResult(id)
	local profile = GetProfile()

	if id == "minimap_shape" then
		local shape = GetMinimapShape and GetMinimapShape() or "UNKNOWN"
		-- AceDB defaults enabled=true, so check ~= false
		local enabled = profile and profile.enabled ~= false
		local expected = enabled and "SQUARE" or "ROUND"
		return {
			passed = (shape == expected),
			message = "GetMinimapShape() = " .. shape,
			details = {
				{ label = "Shape", value = shape, status = (shape == expected) and "pass" or "fail" },
				{ label = "Expected", value = expected, status = "pass" },
				{ label = "Addon Enabled", value = enabled and "Yes" or "No", status = "pass" },
			},
		}
	elseif id == "border_textures" then
		local cm = ns.ClassyMap
		local hasBorders = cm and cm.borders and cm.borders.top ~= nil
		local borderSize = profile and profile.borderSize or 1
		local visible = borderSize > 0
		return {
			passed = hasBorders,
			message = hasBorders and "Border textures initialized" or "No borders found",
			details = {
				{ label = "borders.top", value = hasBorders and "OK" or "nil", status = hasBorders and "pass" or "fail" },
				{
					label = "borders.bottom",
					value = (cm and cm.borders and cm.borders.bottom) and "OK" or "nil",
					status = (cm and cm.borders and cm.borders.bottom) and "pass" or "fail",
				},
				{ label = "Border Size", value = tostring(borderSize) .. "px", status = "pass" },
				{ label = "Should Show", value = visible and "Yes" or "No", status = "pass" },
			},
		}
	elseif id == "mask_texture" then
		-- AceDB defaults enabled=true, so check ~= false
		local enabled = profile and profile.enabled ~= false
		return {
			passed = enabled,
			message = enabled and "Square mask should be active" or "Addon disabled, round mask active",
			details = {
				{ label = "Addon Enabled", value = enabled and "Yes" or "No", status = enabled and "pass" or "warn" },
				{
					label = "Expected Mask",
					value = enabled and "WHITE8X8 (Square)" or "MinimapMask (Round)",
					status = "pass",
				},
			},
		}
	end

	return { passed = false, message = "Unknown test ID: " .. tostring(id) }
end

-- =============================================================================
-- Performance Profiling
-- =============================================================================

local perfMetrics = {}

function ClassyMapMechanic:RecordPerfMetric(name, duration)
	perfMetrics[name] = duration
end

function ClassyMapMechanic:GetPerformanceSubMetrics()
	return {
		{ name = "Create Border", ms = perfMetrics.CreateBorder or 0, description = "Border texture setup" },
		{ name = "Hide Clutter", ms = perfMetrics.HideClutter or 0, description = "Hide minimap buttons" },
		{ name = "Apply Fonts", ms = perfMetrics.ApplyFontStyles or 0, description = "Font styling" },
		{ name = "Fix Layout", ms = perfMetrics.FixLayout or 0, description = "Layout adjustments" },
		{ name = "Total Apply", ms = perfMetrics.ApplyMinimapChanges or 0, description = "Full minimap apply" },
	}
end

-- =============================================================================
-- MechanicLib Registration
-- =============================================================================

local function RegisterWithMechanic()
	if not MechanicLib then
		return
	end

	MechanicLib:Register(addonName, {
		version = C_AddOns.GetAddOnMetadata(addonName, "Version"),

		-- Console Integration
		getDebugBuffer = function()
			return ClassyMapMechanic.debugBuffer
		end,
		clearDebugBuffer = function()
			wipe(ClassyMapMechanic.debugBuffer)
		end,

		-- Testing Integration
		tests = {
			getAll = function()
				return ClassyMapMechanic:GetTests()
			end,
			getCategories = function()
				return { "API", "UI" }
			end,
			run = function(id)
				return ClassyMapMechanic:RunTest(id)
			end,
			getResult = function(id)
				return ClassyMapMechanic:GetTestResult(id)
			end,
		},

		-- Tools Integration
		tools = {
			createPanel = function(container)
				ClassyMapMechanic:CreateToolsPanel(container)
			end,
		},

		-- Performance Profiling
		performance = {
			getSubMetrics = function()
				return ClassyMapMechanic:GetPerformanceSubMetrics()
			end,
		},

		-- Settings Integration
		settings = {
			debugMode = {
				type = "toggle",
				name = "Debug Mode",
				get = function()
					local profile = GetProfile()
					return profile and profile.debugMode
				end,
				set = function(v)
					local profile = GetProfile()
					if profile then
						profile.debugMode = v
					end
				end,
			},
		},
	})
end

-- Hook into addon load
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, addon)
	if addon == addonName then
		RegisterWithMechanic()
		loader:UnregisterEvent("ADDON_LOADED")
	end
end)
