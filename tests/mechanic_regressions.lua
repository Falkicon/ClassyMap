-- Run from the repository root with Lua 5.1.
dofile("Core/init.lua")
local frames, messages = {}, {}
local now, registrationCount = 1, 0
local library, registration
local locale = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})
function LibStub(name)
	if name == "AceLocale-3.0" then
		return {
			GetLocale = function()
				return locale
			end,
		}
	end
	return library
end
function CreateFrame()
	local frame = { scripts = {}, events = {} }
	function frame:RegisterEvent(event)
		self.events[event] = true
	end
	function frame:UnregisterEvent(event)
		self.events[event] = nil
	end
	function frame:SetScript(event, callback)
		self.scripts[event] = callback
	end
	function frame:SetPoint() end
	function frame:SetSize() end
	function frame:SetText(value)
		self.text = value
	end
	function frame:CreateFontString()
		return CreateFrame()
	end
	frames[#frames + 1] = frame
	return frame
end
function GetTime()
	return now
end
function debugprofilestop()
	return now * 1000
end
function wipe(tbl)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end
C_AddOns = {
	GetAddOnMetadata = function()
		return "test"
	end,
}
ClassyMapDB = { profiles = { Default = { debugMode = false } } }
local requested = {}
local addon = { db = { profile = { debugMode = true, borderSize = 1 } } }
function addon:RequestRefresh(scope)
	requested[#requested + 1] = scope
end
local ns = { ClassyMap = addon }
assert(loadfile("Mechanic.lua"))("ClassyMap", ns)
local diagnostics, loader = ClassyMapMechanic, frames[1]
loader.scripts.OnEvent(loader, "ADDON_LOADED", "ClassyMap")
assert(loader.events.ADDON_LOADED, "Missing optional Mechanic must allow later registration")
library = {
	Categories = { CORE = "core" },
	Register = function(_, _, config)
		registrationCount = registrationCount + 1
		registration = config
	end,
	Log = function(_, _, msg)
		messages[#messages + 1] = msg
	end,
}
loader.scripts.OnEvent(loader, "ADDON_LOADED", "!Mechanic")
assert(registrationCount == 1 and not loader.events.ADDON_LOADED)

diagnostics:Log("first")
diagnostics:Log("first")
assert(#diagnostics.debugBuffer == 1 and #messages == 1, "Use active AceDB profile and throttle duplicates")
addon.db.profile = { debugMode = false, borderSize = 1 }
diagnostics:Log("disabled")
assert(#diagnostics.debugBuffer == 1, "Follow active profile changes")
addon.db.profile.debugMode = true
for i = 1, 600 do
	now = now + 1
	diagnostics:Log(tostring(i))
end
assert(#diagnostics.debugBuffer == 500, "Debug history stays bounded")
for index = 1, 20 do
	local name, value = debug.getupvalue(diagnostics.Log, index)
	if not name then
		break
	end
	if name == "logThrottle" then
		local count = 0
		for _ in pairs(value) do
			count = count + 1
		end
		assert(count <= 500, "Throttle keys must not grow beyond retained history")
	end
end
registration.clearDebugBuffer()
diagnostics:Log("600")
assert(#diagnostics.debugBuffer == 1, "Clear resets history and throttle together")

local function texture(shown)
	return {
		IsShown = function()
			return shown
		end,
	}
end
addon.borders = { top = texture(true), bottom = texture(true), left = texture(true), right = texture(true) }
assert(diagnostics:GetTestResult("border_textures").passed)
addon.borders.right = nil
assert(diagnostics:GetTestResult("border_textures").passed == false, "Missing right border must fail")
addon.borders.right = texture(false)
assert(diagnostics:GetTestResult("border_textures").passed == false, "Unexpected hidden border must fail")
addon.db.profile.borderSize = 0
for key in pairs(addon.borders) do
	addon.borders[key] = texture(false)
end
assert(diagnostics:GetTestResult("border_textures").passed, "Zero-size hidden borders are valid")
assert(diagnostics:GetTestResult("mask_texture").passed == nil, "Visual mask checks cannot claim an automatic pass")
function GetMinimapShape()
	return "SQUARE"
end
addon.db.profile.enabled = false -- Obsolete saved flag has no runtime meaning.
assert(diagnostics:GetTestResult("minimap_shape").passed)
-- Empty/reset windows are finite, and snapshots cannot change internal counters.
diagnostics:ResetPerformanceMetrics()
local empty = diagnostics:GetPerformanceStats()
assert(empty.elapsedSeconds == 0 and empty.metrics.Refresh.count == 0)
assert(empty.metrics.CreateBorder.msPerSecond == 0)
assert(#diagnostics:GetPerformanceSubMetrics() == 5)
assert(diagnostics:RecordPerfMetric("CreateBorder", 2.5))
assert(diagnostics:RecordPerfMetric("CreateBorder", 0.5))
assert(diagnostics:RecordPerfMetric("FixLayout", 4))
assert(diagnostics:RecordPerfMetric("Setup", 3))
assert(diagnostics:RecordPerfMetric("Refresh", 12))
now = now + 2
local stats = diagnostics:GetPerformanceStats()
assert(stats.elapsedSeconds == 2)
local border = stats.metrics.CreateBorder
assert(border.count == 2 and border.totalMs == 3 and border.maxMs == 2.5)
assert(border.lastMs == 0.5 and border.averageMs == 1.5)
assert(border.callsPerSecond == 1 and border.msPerSecond == 1.5)
border.totalMs = 999
assert(diagnostics:GetPerformanceStats().metrics.CreateBorder.totalMs == 3)
local total = 0
for _, metric in ipairs(diagnostics:GetPerformanceSubMetrics()) do
	total = total + metric.ms
end
assert(total == 5, "Breakdown rates include categories only, never their inclusive Refresh total")
assert(diagnostics:GetPerformanceSubMetrics()[1].description:find("2 calls", 1, true))
assert(not diagnostics:RecordPerfMetric("CreateBorder", -1))
assert(not diagnostics:RecordPerfMetric("CreateBorder", 0 / 0))
assert(not diagnostics:RecordPerfMetric("CreateBorder", math.huge))
assert(not diagnostics:RecordPerfMetric("CreateBorder", "3"))
for i = 1, 1000 do
	assert(not diagnostics:RecordPerfMetric("unknown" .. i, 1))
end
local entries = 0
for _ in pairs(diagnostics:GetPerformanceStats().metrics) do
	entries = entries + 1
end
assert(entries == 6, "Metric cardinality is fixed")
assert(diagnostics:GetPerformanceStats().metrics.CreateBorder.count == 2)

-- Many inexpensive invocations accumulate measurable work.
for _ = 1, 100 do
	diagnostics:RecordPerfMetric("ApplyFontStyles", 0.125)
end
local fonts = diagnostics:GetPerformanceStats().metrics.ApplyFontStyles
assert(fonts.count == 100 and fonts.totalMs == 12.5 and fonts.maxMs == 0.125)

diagnostics:CreateToolsPanel(CreateFrame())
local found
for _, frame in ipairs(frames) do
	if frame.text == "Reapply" then
		frame.scripts.OnClick()
		found = true
	end
end
assert(
	found and #requested == 1 and requested[1] == "all" and addon.db.profile.enabled == false,
	"Reapply must not pretend to toggle the addon"
)
for _, frame in ipairs(frames) do
	if frame.text == "2" then
		frame.scripts.OnClick()
	end
	if frame.text == "Reset Metrics" then
		frame.scripts.OnClick()
	end
end
assert(requested[2] == "border", "Border tools must use the same refresh scheduler")
assert(diagnostics:GetPerformanceStats().metrics.ApplyFontStyles.count == 0)
assert(diagnostics:GetPerformanceStats().elapsedSeconds == 0)
assert(diagnostics:RecordPerfMetric("FixLayout", 0))
assert(diagnostics:GetPerformanceStats().metrics.FixLayout.count == 1)
assert(diagnostics:RecordPerfMetric("Setup", 1e308))
assert(not diagnostics:RecordPerfMetric("Setup", 1e308), "Cumulative duration must remain finite")
assert(diagnostics:GetPerformanceStats().metrics.Setup.count == 1)
print("Mechanic regressions passed")
