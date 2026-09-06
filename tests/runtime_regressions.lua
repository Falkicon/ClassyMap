-- Offline runtime regression checks: lua tests/runtime_regressions.lua

local Mock = dofile("tests/support/wow_mock.lua")
local Assert = dofile("tests/support/assertions.lua")
local env = Mock.new({ loggedIn = true })

local addon = { events = {} }
function addon:RegisterEvent(event, method)
	method = method or event
	assert(type(method) == "function" or type(self[method]) == "function", "missing event handler")
	self.events[event] = method
end
function addon:UnregisterEvent(event)
	self.events[event] = nil
end
function addon:UnregisterAllEvents()
	self.events = {}
end
function addon:RegisterChatCommand() end
function addon:Print() end

local function fireAddonEvent(event, ...)
	local method = addon.events[event]
	if type(method) == "string" then
		addon[method](addon, event, ...)
	elseif method then
		method(event, ...)
	end
end

local locale = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})
local libraries = {
	["AceAddon-3.0"] = {
		NewAddon = function()
			return addon
		end,
	},
	["AceLocale-3.0"] = {
		GetLocale = function()
			return locale
		end,
	},
	["LibSharedMedia-3.0"] = {
		Fetch = function()
			return "font.ttf"
		end,
	},
	["AceDB-3.0"] = {
		New = function(_, _, defaults)
			return { profile = defaults.profile }
		end,
	},
}
function _G.LibStub(name)
	return assert(libraries[name], "unexpected library: " .. tostring(name))
end

dofile("Core/init.lua")
local namespace = {}
assert(loadfile("ClassyMap.lua"))("ClassyMap", namespace)
addon:OnInitialize()

-- RunSafe preserves trailing nil arguments and re-registers its combat event
-- after each completed combat cycle.
for _ = 1, 2 do
	env:SetCombat(true)
	addon:RunSafe(function(_, ...)
		Assert.equal(select("#", ...), 3, "RunSafe lost trailing nil arguments")
	end, "a", nil, nil)
	Assert.equal(addon.events.PLAYER_REGEN_ENABLED, "ProcessCombatQueue", "RunSafe registered the wrong handler")
	env:SetCombat(false)
	fireAddonEvent("PLAYER_REGEN_ENABLED")
	Assert.equal(addon.events.PLAYER_REGEN_ENABLED, nil, "completed combat cycle left its event registered")
end

-- One failing queued action cannot discard later work or work queued by a callback.
local nestedRuns = 0
env:SetCombat(true)
addon:RunSafe(function()
	error("expected queued failure")
end)
addon:RunSafe(function()
	nestedRuns = nestedRuns + 1
	ClassyMapCore:QueueAction(function()
		nestedRuns = nestedRuns + 1
	end)
end)
env:SetCombat(false)
fireAddonEvent("PLAYER_REGEN_ENABLED")
env:FlushTimers()
Assert.equal(nestedRuns, 2, "error or nested queue work discarded a later action")
Assert.equal(#env.errors, 1, "queued error was not isolated")
Assert.equal(addon.events.PLAYER_REGEN_ENABLED, nil, "nested queue drain left its event registered")
env.errors = {}

local calls = {}
for _, method in ipairs({ "ApplyMinimapChanges", "CreateBorder", "HideMinimapClutter", "ApplyFontStyles", "FixLayout" }) do
	local original = addon[method]
	addon[method] = function(self, ...)
		calls[method] = (calls[method] or 0) + 1
		return original(self, ...)
	end
end
local function resetCalls()
	for key in pairs(calls) do
		calls[key] = nil
	end
	env:ResetCounts()
end

-- Enabling is a queued lifecycle boundary and a full refresh performs each category once.
addon:OnEnable()
Assert.equal(Minimap.maskTexture, "native-mask", "OnEnable refreshed synchronously")
Assert.equal(#env.timers, 1, "OnEnable did not schedule one refresh")
env:FlushTimers()
Assert.equal(calls.ApplyMinimapChanges, 1, "startup did not perform one full refresh")
Assert.equal(calls.CreateBorder, 1, "startup did not create the border once")
Assert.equal(calls.HideMinimapClutter, 1, "startup did not apply visibility once")
Assert.equal(calls.ApplyFontStyles, 1, "startup did not apply fonts once")
Assert.equal(calls.FixLayout, 1, "startup did not apply layout once")
Assert.equal(#env.errors, 0, "startup reported an error")

-- Both Blizzard dimension hooks coalesce, and a layout error cannot strand the guard.
resetCalls()
MinimapCluster:SetWidth(200)
MinimapCluster:SetHeight(210)
Assert.equal(#env.timers, 1, "width/height hooks did not coalesce")
env:FlushTimers()
Assert.equal(calls.FixLayout, 1, "dimension hooks did not request one layout pass")
Assert.equal(#env.timers, 0, "layout's own dimensions recursively scheduled work")

resetCalls()
local setPoint = Minimap.SetPoint
Minimap.SetPoint = function()
	error("expected layout failure")
end
addon:RequestRefresh("layout")
env:FlushTimers()
Assert.equal(addon.resizing, nil, "layout failure left the recursion guard set")
Assert.equal(#env.errors, 1, "layout failure was not reported once")
Minimap.SetPoint = setPoint
env.errors = {}
addon:RequestRefresh("layout")
env:FlushTimers()
Assert.equal(calls.FixLayout, 2, "layout did not recover after an exception")
Assert.equal(#env.errors, 0, "recovered layout still reported an error")

-- Partial categories coalesce into one timer and visibility includes one layout pass.
resetCalls()
addon:RequestRefresh("border")
addon:RequestRefresh("fonts")
addon:RequestRefresh("visibility")
addon:RequestRefresh("layout")
addon:RequestRefresh("fonts")
Assert.equal(#env.timers, 1, "partial refresh requests did not coalesce")
env:FlushTimers()
Assert.equal(calls.ApplyMinimapChanges, nil, "partial work ran the full refresh")
Assert.equal(calls.CreateBorder, 1, "border category did not run exactly once")
Assert.equal(calls.HideMinimapClutter, 1, "visibility category did not run exactly once")
Assert.equal(calls.ApplyFontStyles, 1, "font category did not run exactly once")
Assert.equal(calls.FixLayout, 1, "layout category did not run exactly once")

-- Independently requested work records its category and one aggregate refresh.
local metrics = {}
ClassyMapMechanic = {
	RecordPerfMetric = function(_, name, duration)
		assert(
			type(duration) == "number" and duration == duration and math.abs(duration) < math.huge,
			"non-finite metric"
		)
		metrics[#metrics + 1] = name
	end,
}
local function assertMetricNames(first, second)
	Assert.equal(#metrics, 2, "partial refresh recorded the wrong number of metrics")
	Assert.equal(metrics[1], first, "partial refresh recorded the wrong category metric")
	Assert.equal(metrics[2], second, "partial refresh recorded the wrong aggregate metric")
	metrics = {}
end
addon:RequestRefresh("fonts")
env:FlushTimers()
assertMetricNames("ApplyFontStyles", "Refresh")
addon:RequestRefresh("layout")
env:FlushTimers()
assertMetricNames("FixLayout", "Refresh")
ClassyMapMechanic = nil

-- A full refresh supersedes pending category work instead of duplicating it.
resetCalls()
addon:RequestRefresh("border")
addon:RequestRefresh("all")
addon:RequestRefresh("fonts")
env:FlushTimers()
Assert.equal(calls.ApplyMinimapChanges, 1, "all scope did not run one full refresh")
Assert.equal(calls.CreateBorder, 1, "pending border work ran twice")
Assert.equal(calls.ApplyFontStyles, 1, "pending font work ran twice")
Assert.raises("Unknown refresh scope", function()
	addon:RequestRefresh("typo")
end)

-- Protected writes are rejected by the mock, while scheduler work waits for regen.
resetCalls()
env:SetCombat(true)
Assert.raises("protected mutation", function()
	Minimap:SetPoint("CENTER")
end)
for _ = 1, 10 do
	addon:RequestRefresh("all")
end
Assert.equal(#env.timers, 0, "combat refresh scheduled a mutating timer")
Assert.equal(calls.ApplyMinimapChanges, nil, "combat refresh touched protected frames")
Assert.equal(addon.events.PLAYER_REGEN_ENABLED, "ProcessCombatQueue", "regen handler was not registered")
env:SetCombat(false)
fireAddonEvent("PLAYER_REGEN_ENABLED")
Assert.equal(#env.timers, 1, "regen did not schedule pending work")
env:FlushTimers()
Assert.equal(calls.ApplyMinimapChanges, 1, "combat refresh did not drain once")

-- A failing category cannot prevent independent pending work.
resetCalls()
local createBorder = addon.CreateBorder
addon.CreateBorder = function()
	error("expected border failure")
end
addon:RequestRefresh("border")
addon:RequestRefresh("fonts")
env:FlushTimers()
addon.CreateBorder = createBorder
Assert.equal(calls.ApplyFontStyles, 1, "a border error discarded font work")
Assert.equal(#env.errors, 1, "category error was not isolated and reported")
env.errors = {}

-- The clock FontString is targeted even if the button's first region is a Texture.
local firstRegion = env:NewFrame("ClockTexture", { objectType = "Texture" })
Assert.raises("attempt to call", function()
	firstRegion:SetFont("bad.ttf", 10)
end)
TimeManagerClockButton = env:NewFrame("TimeManagerClockButton", {
	parent = MinimapCluster,
	protected = true,
	regions = { n = 1, firstRegion },
})
TimeManagerClockTicker = env:NewFrame("TimeManagerClockTicker", {
	objectType = "FontString",
	parent = TimeManagerClockButton,
	protected = true,
})
resetCalls()
fireAddonEvent("ADDON_LOADED", "Blizzard_TimeManager")
Assert.equal(#env.timers, 1, "late clock load was not queued")
env:FlushTimers()
local _, clockSize = TimeManagerClockTicker:GetFont()
Assert.equal(clockSize, addon.db.profile.clockFontSize, "named clock FontString was not styled")

addon.db.profile.hideZoneText = true
addon:RequestRefresh("visibility")
env:FlushTimers()
Assert.point(
	TimeManagerClockButton,
	1,
	{ "TOP", Minimap, "TOP", 0, -4 },
	"hidden zone heading left the clock anchored beneath it"
)
addon.db.profile.hideZoneText = false
addon:RequestRefresh("visibility")
env:FlushTimers()

-- Hybrid mask ownership stays consistent with the retained square base mask.
HybridMinimap = {
	MapCanvas = env:NewFrame("HybridMapCanvas", { useMaskTexture = false }),
	CircleMask = env:NewFrame("HybridCircleMask", {
		objectType = "Texture",
		texture = "native-hybrid-mask",
	}),
}
fireAddonEvent("ADDON_LOADED", "Blizzard_HybridMinimap")
env:FlushTimers()
Assert.equal(HybridMinimap.MapCanvas:GetUseMaskTexture(), true, "hybrid masking was not enabled")
Assert.equal(
	HybridMinimap.CircleMask:GetTexture(),
	"Interface\\BUTTONS\\WHITE8X8",
	"hybrid map did not receive the square mask"
)

-- Native zone changes update the restoration baseline, then reapply an enabled override.
addon.db.profile.overrideZoneColor = true
addon.db.profile.zoneTextColor = { r = 1, g = 0, b = 0, a = 1 }
addon:RequestRefresh("fonts")
env:FlushTimers()
local red = { MinimapZoneText:GetTextColor() }
Assert.equal(red[1], 1, "zone override was not applied")
env.nativeZoneColor = Mock.pack(0.2, 0.4, 0.8, 1)
Minimap_Update()
env:FlushTimers()
red = { MinimapZoneText:GetTextColor() }
Assert.equal(red[1], 1, "native zone update displaced an enabled override")

addon:OnDisable()
local restoredNative = { MinimapZoneText:GetTextColor() }
Assert.equal(restoredNative[1], 0.2, "disable restored a stale pre-zone-change color")
Assert.equal(restoredNative[2], 0.4, "disable lost the latest native zone color")
Assert.equal(GetMinimapShape(), "SQUARE", "disable made shape reporting disagree with the retained mask")
Assert.equal(HybridMinimap.MapCanvas:GetUseMaskTexture(), true, "disable broke hybrid mask usage")
Assert.equal(
	HybridMinimap.CircleMask:GetTexture(),
	"Interface\\BUTTONS\\WHITE8X8",
	"disable made the hybrid mask disagree with the retained square shape"
)
addon:OnEnable()
env:FlushTimers()

-- A stale timer and combat queue from an earlier generation cannot run after
-- disable/re-enable; the new enable still performs its own refresh.
resetCalls()
addon:RequestRefresh("border")
addon:OnDisable()
addon:OnEnable()
env:FlushTimers()
Assert.equal(calls.ApplyMinimapChanges, 1, "re-enable did not perform one fresh full refresh")
Assert.equal(calls.CreateBorder, 1, "a stale pre-disable timer performed extra border work")

local cancelledRun = 0
env:SetCombat(true)
addon:RunSafe(function()
	cancelledRun = cancelledRun + 1
end)
addon:OnDisable()
addon:OnEnable()
env:SetCombat(false)
fireAddonEvent("PLAYER_REGEN_ENABLED")
env:FireEvent("PLAYER_REGEN_ENABLED")
env:FlushTimers()
Assert.equal(cancelledRun, 0, "a stale pre-disable combat action ran after re-enable")

-- Another shape owner also owns the base mask once it takes over.
local foreignShape = function()
	return "HEXAGON"
end
GetMinimapShape = foreignShape
Minimap:SetMaskTexture("foreign-mask")
addon:RequestRefresh("all")
env:FlushTimers()
Assert.equal(GetMinimapShape, foreignShape, "full refresh overwrote a foreign shape owner")
Assert.equal(Minimap.maskTexture, "foreign-mask", "full refresh overwrote a foreign base mask")

-- Restore the ClassyMap policy for the remaining restoration checks.
GetMinimapShape = addon.shapeOverride
Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")

-- An external color takeover is preserved when the override is turned off.
MinimapZoneText:SetTextColor(0.7, 0.2, 0.9, 1)
addon.db.profile.overrideZoneColor = false
addon:RequestRefresh("fonts")
env:FlushTimers()
local externalColor = { MinimapZoneText:GetTextColor() }
Assert.equal(externalColor[1], 0.7, "disabling the override replaced an external color")

-- Pending callbacks are invalidated on disable and externally-owned state survives restoration.
local externalParent = env:NewFrame("ExternalOwner")
GameTimeFrame:SetParent(externalParent)
GameTimeFrame:ClearAllPoints()
GameTimeFrame:SetPoint("BOTTOM", externalParent, "BOTTOM", 9, 10)
GameTimeFrame:Hide()
local borderCalls = calls.CreateBorder or 0
addon:RequestRefresh("border")
addon:OnDisable()
env:FlushTimers()
Assert.equal(calls.CreateBorder or 0, borderCalls, "disabled timer performed pending border work")
Assert.equal(GameTimeFrame:GetParent(), externalParent, "disable overwrote an external parent")
Assert.point(GameTimeFrame, 1, { "BOTTOM", externalParent, "BOTTOM", 9, 10 }, "disable overwrote external anchors")
Assert.equal(GameTimeFrame:IsShown(), false, "disable overwrote external visibility")
Assert.point(Minimap, 1, { "CENTER", MinimapCluster, "CENTER", 3, 4 }, "owned minimap anchor was not restored")
Assert.equal(MinimapCompassTexture:IsShown(), true, "owned compass visibility was not restored")
Assert.equal(MinimapCompassTexture:GetAlpha(), 1, "owned compass alpha was not restored")

-- Permanent hooks are gated while disabled.
resetCalls()
ExpansionLandingPageMinimapButton:Hide()
ExpansionLandingPageMinimapButton:Show()
Minimap_Update()
MinimapCluster:SetWidth(177)
Assert.equal(ExpansionLandingPageMinimapButton:IsShown(), true, "disabled expansion hook hid native UI")
Assert.equal(#env.timers, 0, "disabled hooks scheduled refresh work")

-- Re-enable captures current external state as the new restoration baseline.
addon:OnEnable()
env:FlushTimers()
Assert.equal(GameTimeFrame:GetParent(), Minimap, "re-enable did not reacquire layout ownership")
addon:OnDisable()
Assert.equal(GameTimeFrame:GetParent(), externalParent, "second disable did not restore the new baseline")
Assert.point(
	GameTimeFrame,
	1,
	{ "BOTTOM", externalParent, "BOTTOM", 9, 10 },
	"second disable lost the new anchor baseline"
)
Assert.equal(#env.errors, 0, "runtime regressions reported unexpected errors")

print("runtime regressions passed")
