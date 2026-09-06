-- Standalone settings checks: lua tests/settings_regressions.lua

local Mock = dofile("tests/support/wow_mock.lua")
local Assert = dofile("tests/support/assertions.lua")
local env = Mock.new()

local registeredOptions
local addToOptionsCalls, openCalls, notifyCalls = 0, 0, 0
local locale = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})
local libraries = {
	["AceLocale-3.0"] = {
		GetLocale = function()
			return locale
		end,
	},
	["AceConfig-3.0"] = {
		RegisterOptionsTable = function(_, name, options)
			Assert.equal(name, "ClassyMap", "wrong options-table name")
			registeredOptions = options
		end,
	},
	["AceConfigDialog-3.0"] = {
		AddToBlizOptions = function()
			addToOptionsCalls = addToOptionsCalls + 1
			return {}
		end,
		Open = function()
			openCalls = openCalls + 1
		end,
	},
	["AceConfigRegistry-3.0"] = {
		NotifyChange = function(_, name)
			Assert.equal(name, "ClassyMap", "wrong notification target")
			notifyCalls = notifyCalls + 1
		end,
	},
	["AceDBOptions-3.0"] = {
		GetOptionsTable = function()
			return { type = "group", name = "Profiles" }
		end,
	},
	["LibSharedMedia-3.0"] = {
		HashTable = function()
			return { Default = "font.ttf" }
		end,
	},
}

function _G.LibStub(name)
	return assert(libraries[name], "unexpected library: " .. tostring(name))
end

local callbacks, refreshes = {}, {}
local database = {
	profile = {
		borderSize = 0 / 0,
		borderColor = "invalid",
		zoneFontSize = math.huge,
		zoneTextColor = "invalid",
		clockFontSize = -math.huge,
		clockTextColor = "invalid",
	},
	RegisterCallback = function(receiver, event, method)
		callbacks[event] = { receiver = receiver, method = method }
	end,
}
local namespace = {
	ClassyMap = {
		db = database,
		RequestRefresh = function(_, category)
			refreshes[#refreshes + 1] = category
		end,
	},
}

dofile("Core/init.lua")
assert(loadfile("Settings.lua"))("ClassyMap", namespace)
env:FireEvent("ADDON_LOADED", "ClassyMap")

Assert.equal(addToOptionsCalls, 1, "settings were not registered exactly once")
Assert.truthy(callbacks.OnProfileChanged, "profile-change callback was not registered")
Assert.truthy(callbacks.OnProfileCopied, "profile-copy callback was not registered")
Assert.truthy(callbacks.OnProfileReset, "profile-reset callback was not registered")

local options = registeredOptions()
Assert.truthy(options.args.profiles, "profile options were not exposed")
Assert.equal(options.args.profiles.order, 100, "profile options order is incorrect")
Assert.equal(options.args.borderSize.get(), 1, "invalid border size was not normalized")
Assert.equal(options.args.zoneFontSize.get(), 11, "invalid zone font size was not normalized")
Assert.equal(options.args.clockFontSize.get(), 11, "invalid clock font size was not normalized")
Assert.equal(options.args.zoneFontSize.max, 24, "zone font range does not match core validation")
Assert.equal(options.args.clockFontSize.max, 24, "clock font range does not match core validation")
local r, g, b, a = options.args.borderColor.get()
assert(r == 1 and g == 1 and b == 1 and a == 1, "invalid color was not normalized")

local expectedCategories = {
	borderSize = "border",
	borderColor = "border",
	font = "fonts",
	zoneFontSize = "fonts",
	overrideZoneColor = "fonts",
	zoneTextColor = "fonts",
	clockFontSize = "fonts",
	clockTextColor = "fonts",
	hideTracking = "visibility",
	hideZoneText = "visibility",
	hideClock = "visibility",
	hideZoomButtons = "visibility",
	hideExpansionButton = "visibility",
	hideCalendar = "visibility",
	hideAddonBtn = "visibility",
	hideInstance = "visibility",
}
for optionName, category in pairs(expectedCategories) do
	local option = options.args[optionName]
	local before = #refreshes
	if option.type == "color" then
		option.set(nil, 0.2, 0.3, 0.4, 0.5)
	elseif option.type == "toggle" then
		option.set(nil, true)
	elseif option.type == "select" then
		option.set(nil, "Default")
	else
		option.set(nil, option.min)
	end
	Assert.equal(#refreshes, before + 1, optionName .. " did not request one refresh")
	Assert.equal(refreshes[#refreshes], category, optionName .. " requested the wrong category")
end

namespace.Settings:Initialize()
Assert.equal(addToOptionsCalls, 1, "settings initialization is not idempotent")

namespace.Settings:OnProfileUpdated()
Assert.equal(refreshes[#refreshes], "all", "profile refresh did not request all work")
Assert.equal(notifyCalls, 1, "profile refresh did not notify AceConfig")

namespace.Settings:OpenOptions()
Assert.equal(openCalls, 1, "settings dialog did not open")

-- Strict mocks fail at the access site instead of accepting misspelled APIs.
Assert.raises("attempt to call", function()
	return Minimap:DefinitelyNotAFrameMethod()
end)

print("settings regressions passed")
