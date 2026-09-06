-- ClassyMap Mechanic Integration
-- Provides MechanicLib registration, tools panel, in-game tests, and debug logging

local addonName, ns = ...
local MechanicLib = LibStub("MechanicLib-1.0", true)
local L = LibStub("AceLocale-3.0"):GetLocale("ClassyMap")

local function GetProfile()
	local addon = ns.ClassyMap
	return addon and addon.db and addon.db.profile
end

---@class ClassyMapMechanic
ClassyMapMechanic = {}
ClassyMapMechanic.debugBuffer = {}

-- =============================================================================
-- Throttled Debug Logging (Console-only, no chat spam)
-- =============================================================================

local logThrottle = {}
local LOG_INTERVAL = 0.1 -- seconds between identical messages

function ClassyMapMechanic:Log(msg, category)
	local profile = GetProfile()
	if not profile or not profile.debugMode then
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
		local removed = table.remove(self.debugBuffer, 1)
		if logThrottle[removed.msg] == removed.time then
			logThrottle[removed.msg] = nil
		end
	end

	-- Log to Mechanic's console only (no chat spam)
	if MechanicLib then
		MechanicLib:Log(addonName, msg, category or MechanicLib.Categories.CORE)
	end
end

-- =============================================================================
-- Tools Panel (Button-based)
-- =============================================================================

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
	title:SetText(L["ClassyMap Tools"])

	-- Description
	local desc = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 10, -35)
	desc:SetText(L["Quick actions for minimap customization."])

	-- Row 1: Reapply & Settings (the addon does not implement runtime disable)
	local row1Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row1Label:SetPoint("TOPLEFT", 10, -65)
	row1Label:SetText(L["Addon:"])

	CreateToolButton(container, 80, -60, 80, L["Reapply"], function()
		if GetProfile() then
			ns.ClassyMap:RequestRefresh("all")
		else
			print(L["|cffff0000ClassyMap:|r Not initialized yet"])
		end
	end)

	CreateToolButton(container, 165, -60, 80, L["Settings"], function()
		if ns.Settings then
			ns.Settings:OpenOptions()
		else
			print(L["|cffff0000ClassyMap:|r Settings not available"])
		end
	end)

	-- Row 2: Border Size
	local row2Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row2Label:SetPoint("TOPLEFT", 10, -100)
	row2Label:SetText(L["Border:"])

	CreateToolButton(container, 80, -95, 50, "0", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 0
			if ns.ClassyMap then
				ns.ClassyMap:RequestRefresh("border")
			end
			print(L["|cff00ff00ClassyMap:|r Border hidden"])
		end
	end)

	CreateToolButton(container, 135, -95, 50, "1", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 1
			if ns.ClassyMap then
				ns.ClassyMap:RequestRefresh("border")
			end
			print(L["|cff00ff00ClassyMap:|r Border = 1px"])
		end
	end)

	CreateToolButton(container, 190, -95, 50, "2", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 2
			if ns.ClassyMap then
				ns.ClassyMap:RequestRefresh("border")
			end
			print(L["|cff00ff00ClassyMap:|r Border = 2px"])
		end
	end)

	CreateToolButton(container, 245, -95, 50, "4", function()
		local profile = GetProfile()
		if profile then
			profile.borderSize = 4
			if ns.ClassyMap then
				ns.ClassyMap:RequestRefresh("border")
			end
			print(L["|cff00ff00ClassyMap:|r Border = 4px"])
		end
	end)

	-- Row 3: Debug
	local row3Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row3Label:SetPoint("TOPLEFT", 10, -135)
	row3Label:SetText(L["Debug:"])

	CreateToolButton(container, 80, -130, 100, L["Toggle Debug"], function()
		local profile = GetProfile()
		if profile then
			profile.debugMode = not profile.debugMode
			print(L["Debug Mode"] .. ": " .. (profile.debugMode and L["Enabled"] or L["Disabled"]))
		end
	end)

	CreateToolButton(container, 190, -130, 110, L["Reset Metrics"], function()
		self:ResetPerformanceMetrics()
	end)

	-- Footer
	local footer = container:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	footer:SetPoint("BOTTOM", 0, 10)
	footer:SetText(L["Use /classymap or /cm for more options."])
end

-- =============================================================================
-- In-Game Tests
-- =============================================================================

ClassyMapMechanic.tests = {
	{
		id = "minimap_shape",
		name = L["Minimap Shape Override"],
		category = "API",
		type = "auto",
		description = L["Verifies GetMinimapShape returns SQUARE."],
	},
	{
		id = "border_textures",
		name = L["Border Textures"],
		category = "UI",
		type = "auto",
		description = L["Checks border textures are created and visible."],
	},
	{
		id = "mask_texture",
		name = L["Square Mask Applied"],
		category = "UI",
		type = "manual",
		description = L["Verifies the square mask is applied to Minimap."],
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
		local expected = "SQUARE"
		return {
			passed = (shape == expected),
			message = L["GetMinimapShape() = %s"]:format(tostring(shape)),
			details = {
				{ label = L["Shape"], value = shape, status = (shape == expected) and "pass" or "fail" },
				{ label = L["Expected"], value = expected, status = "pass" },
			},
		}
	elseif id == "border_textures" then
		local cm = ns.ClassyMap
		local borderSize = ClassyMapCore:ValidateBorderSize(profile and profile.borderSize)
		local visible = borderSize > 0
		local passed = true
		local details = {}
		for _, side in ipairs({ "top", "bottom", "left", "right" }) do
			local texture = cm and cm.borders and cm.borders[side]
			local matches = texture ~= nil and texture:IsShown() == visible
			passed = passed and matches
			details[#details + 1] = {
				label = L["borders."] .. side,
				value = texture and (texture:IsShown() and L["Shown"] or L["Hidden"]) or L["Missing"],
				status = matches and "pass" or "fail",
			}
		end
		return {
			passed = passed,
			message = L["Border visibility matches the configured size: %s"]:format(tostring(borderSize)),
			details = details,
		}
	elseif id == "mask_texture" then
		return {
			message = L["Visual check required: confirm the minimap and hybrid minimap have square corners."],
		}
	end

	return { passed = false, message = L["Unknown test ID: %s"]:format(tostring(id)) }
end

-- =============================================================================
-- Performance Profiling
-- =============================================================================

-- Only executed work is measured. Fixed names keep memory bounded for the session.
local metricDefinitions = {
	{ id = "CreateBorder", name = L["Create Border"] },
	{ id = "HideClutter", name = L["Hide Clutter"] },
	{ id = "ApplyFontStyles", name = L["Apply Fonts"] },
	{ id = "FixLayout", name = L["Fix Layout"] },
	{ id = "Setup", name = L["Map Setup"] },
}
local knownMetrics = { Refresh = true }
for _, definition in ipairs(metricDefinitions) do
	knownMetrics[definition.id] = true
end
local perfMetrics = {}
local metricsStartedAt = GetTime()

local function EmptyMetric()
	return { count = 0, totalMs = 0, maxMs = 0, lastMs = 0 }
end

function ClassyMapMechanic:RecordPerfMetric(name, duration)
	if
		not knownMetrics[name]
		or type(duration) ~= "number"
		or duration ~= duration
		or duration < 0
		or duration == math.huge
	then
		return false
	end
	local metric = perfMetrics[name]
	local total = (metric and metric.totalMs or 0) + duration
	if total == math.huge then
		return false
	end
	if not metric then
		metric = EmptyMetric()
		perfMetrics[name] = metric
	end
	metric.count = metric.count + 1
	metric.totalMs = total
	metric.maxMs = math.max(metric.maxMs, duration)
	metric.lastMs = duration
	return true
end

function ClassyMapMechanic:ResetPerformanceMetrics()
	wipe(perfMetrics)
	metricsStartedAt = GetTime()
end

-- A detached snapshot is safe for diagnostic consumers to retain or modify.
-- Refresh is an inclusive batch total; it is never added to the category breakdown.
function ClassyMapMechanic:GetPerformanceStats()
	local elapsed = math.max(0, GetTime() - metricsStartedAt)
	local snapshot = { elapsedSeconds = elapsed, metrics = {} }
	for name in pairs(knownMetrics) do
		local source = perfMetrics[name] or EmptyMetric()
		snapshot.metrics[name] = {
			count = source.count,
			totalMs = source.totalMs,
			maxMs = source.maxMs,
			lastMs = source.lastMs,
			averageMs = source.count > 0 and source.totalMs / source.count or 0,
			callsPerSecond = elapsed > 0 and source.count / elapsed or 0,
			msPerSecond = elapsed > 0 and source.totalMs / elapsed or 0,
		}
	end
	return snapshot
end

function ClassyMapMechanic:GetPerformanceSubMetrics()
	local snapshot = self:GetPerformanceStats()
	local result = {}
	for _, definition in ipairs(metricDefinitions) do
		local metric = snapshot.metrics[definition.id]
		result[#result + 1] = {
			name = definition.name,
			-- Mechanic's breakdown and total are labeled ms/s.
			ms = metric.msPerSecond,
			count = metric.count,
			totalMs = metric.totalMs,
			averageMs = metric.averageMs,
			maxMs = metric.maxMs,
			lastMs = metric.lastMs,
			description = L["%d calls; %.3f ms total; %.3f ms average; %.3f ms max; %.3f ms last"]:format(
				metric.count,
				metric.totalMs,
				metric.averageMs,
				metric.maxMs,
				metric.lastMs
			),
		}
	end
	return result
end

-- =============================================================================
-- MechanicLib Registration
-- =============================================================================

local function RegisterWithMechanic()
	MechanicLib = LibStub("MechanicLib-1.0", true)
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
			wipe(logThrottle)
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
				name = L["Debug Mode"],
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
	return true
end

-- Hook into addon load
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, addon)
	if addon == addonName or addon == "!Mechanic" or addon == "Mechanic" then
		if RegisterWithMechanic() then
			loader:UnregisterEvent("ADDON_LOADED")
		end
	end
end)
