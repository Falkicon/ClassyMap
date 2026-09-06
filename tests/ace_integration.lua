-- Bundled Ace lifecycle integration: lua tests/ace_integration.lua

local Mock = dofile("tests/support/wow_mock.lua")
local Assert = dofile("tests/support/assertions.lua")
local nativeXpcall = xpcall

local function installAceLibraries(env)
	-- WoW's xpcall accepts arguments; Lua 5.1's stock implementation does not.
	_G.xpcall = function(callback, errorHandler, ...)
		local args = Mock.pack(...)
		return nativeXpcall(function()
			return callback(unpack(args, 1, args.n))
		end, errorHandler)
	end
	_G.LibStub = nil
	_G.ClassyMapDB = nil
	_G.ClassyMapCore = nil
	_G.ClassyMapMechanic = nil
	_G.SLASH_ACECONSOLE_CLASSYMAP1 = nil
	_G.SLASH_ACECONSOLE_CM1 = nil

	dofile("Libs/LibStub/LibStub.lua")
	dofile("Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
	dofile("Libs/AceAddon-3.0/AceAddon-3.0.lua")
	dofile("Libs/AceDB-3.0/AceDB-3.0.lua")
	dofile("Libs/AceConsole-3.0/AceConsole-3.0.lua")
	dofile("Libs/AceEvent-3.0/AceEvent-3.0.lua")
	dofile("Libs/AceLocale-3.0/AceLocale-3.0.lua")

	local sharedMedia = assert(LibStub:NewLibrary("LibSharedMedia-3.0", 1))
	function sharedMedia:Fetch()
		return "font.ttf"
	end
	function sharedMedia:HashTable()
		return { Default = "font.ttf" }
	end

	local registrations = { notify = 0, options = 0 }
	local aceConfig = assert(LibStub:NewLibrary("AceConfig-3.0", 1))
	function aceConfig:RegisterOptionsTable(_, options)
		registrations.options = registrations.options + 1
		registrations.optionsFactory = options
	end
	local dialog = assert(LibStub:NewLibrary("AceConfigDialog-3.0", 1))
	function dialog:AddToBlizOptions()
		return {}
	end
	function dialog:Open()
		registrations.opened = true
	end
	local registry = assert(LibStub:NewLibrary("AceConfigRegistry-3.0", 1))
	function registry:NotifyChange(name)
		Assert.equal(name, "ClassyMap", "wrong AceConfig notification")
		registrations.notify = registrations.notify + 1
	end
	local dbOptions = assert(LibStub:NewLibrary("AceDBOptions-3.0", 1))
	function dbOptions:GetOptionsTable()
		return { type = "group", name = "Profiles" }
	end

	dofile("Locales/enUS.lua")
	dofile("Core/init.lua")
	local namespace = {}
	assert(loadfile("ClassyMap.lua"))("ClassyMap", namespace)
	assert(loadfile("Settings.lua"))("ClassyMap", namespace)
	return namespace, LibStub("AceAddon-3.0"), registrations
end

local function instrumentRefreshes(addon)
	local requests = {}
	local original = addon.RequestRefresh
	function addon:RequestRefresh(category)
		requests[#requests + 1] = category
		return original(self, category)
	end
	return requests
end

local function runBeforeLoginScenario()
	local env = Mock.new({ loggedIn = false })
	local namespace, aceAddon, registrations = installAceLibraries(env)
	local addon = namespace.ClassyMap
	local requests = instrumentRefreshes(addon)

	Assert.equal(addon.db, nil, "addon initialized before ADDON_LOADED")
	env:FireEvent("ADDON_LOADED", "ClassyMap")
	Assert.truthy(addon.db, "AceAddon did not initialize ClassyMap")
	Assert.equal(not aceAddon.statuses.ClassyMap, true, "addon enabled before login")
	Assert.equal(registrations.options, 1, "Settings did not initialize after the database")
	Assert.equal(#requests, 0, "disabled startup requested a refresh")
	Assert.equal(Minimap.maskTexture, "native-mask", "disabled startup mutated the minimap")

	env:SetLoggedIn(true)
	env:FireEvent("PLAYER_LOGIN")
	Assert.equal(aceAddon.statuses.ClassyMap, true, "PLAYER_LOGIN did not enable ClassyMap")
	Assert.equal(requests[#requests], "all", "enable did not request a complete refresh")
	Assert.equal(Minimap.maskTexture, "native-mask", "enable refreshed synchronously")
	env:FlushTimers()
	Assert.equal(Minimap.maskTexture, "Interface\\BUTTONS\\WHITE8X8", "scheduled startup refresh did not run")
	Assert.equal(#env.errors, 0, "Ace lifecycle reported an error: " .. tostring(env.errors[1]))

	-- These are real AceDB callbacks registered by Settings.
	local db = addon.db
	db.profile.borderSize = 3
	db:SetProfile("Alternate")
	Assert.equal(requests[#requests], "all", "OnProfileChanged did not request all work")
	env:FlushTimers()
	db.profile.borderSize = 5
	db:SetProfile("Source")
	env:FlushTimers()
	db.profile.borderSize = 7
	db:SetProfile("Alternate")
	env:FlushTimers()
	db:CopyProfile("Source")
	Assert.equal(db.profile.borderSize, 7, "AceDB did not copy the profile")
	Assert.equal(requests[#requests], "all", "OnProfileCopied did not request all work")
	env:FlushTimers()
	db:ResetProfile()
	Assert.equal(db.profile.borderSize, 1, "AceDB did not restore profile defaults")
	Assert.equal(requests[#requests], "all", "OnProfileReset did not request all work")
	env:FlushTimers()
	Assert.equal(registrations.notify, 5, "profile callbacks did not notify AceConfig")

	-- AceAddon disables AceEvent after OnDisable returns. Combat restoration must
	-- therefore survive on the addon's private one-shot event frame.
	env:SetCombat(true)
	addon:RequestRefresh("border")
	addon:Disable()
	Assert.equal(aceAddon.statuses.ClassyMap, false, "AceAddon did not disable ClassyMap")
	Assert.truthy(addon.restoreFrame, "combat disable did not create a restoration frame")
	Assert.equal(
		addon.restoreFrame:IsEventRegistered("PLAYER_REGEN_ENABLED"),
		true,
		"AceEvent cleanup removed the private restoration event"
	)
	Assert.point(Minimap, 1, { "CENTER", MinimapCluster, "CENTER", 0, 0 }, "combat disable mutated protected anchors")
	env:SetCombat(false)
	env:FireEvent("PLAYER_REGEN_ENABLED")
	env:FlushTimers()
	Assert.point(Minimap, 1, { "CENTER", MinimapCluster, "CENTER", 3, 4 }, "regen did not restore owned anchors")
	Assert.equal(addon.restorePending, nil, "combat restoration remained pending")
	Assert.equal(#env.errors, 0, "profile callbacks reported an error")
end

local function runLoadOnDemandScenario()
	local env = Mock.new({ loggedIn = true })
	local namespace, aceAddon = installAceLibraries(env)
	local addon = namespace.ClassyMap
	local requests = instrumentRefreshes(addon)

	env:FireEvent("ADDON_LOADED", "ClassyMap")
	Assert.equal(aceAddon.statuses.ClassyMap, true, "logged-in ADDON_LOADED did not enable ClassyMap")
	Assert.equal(requests[#requests], "all", "load-on-demand enable did not request all work")
	Assert.equal(Minimap.maskTexture, "native-mask", "load-on-demand refresh ran synchronously")
	env:FlushTimers()

	TimeManagerClockButton = env:NewFrame("TimeManagerClockButton", {
		parent = MinimapCluster,
		protected = true,
	})
	TimeManagerClockTicker = env:NewFrame("TimeManagerClockTicker", {
		objectType = "FontString",
		parent = TimeManagerClockButton,
		protected = true,
	})
	local before = #requests
	env:FireEvent("ADDON_LOADED", "Blizzard_TimeManager")
	Assert.equal(#requests, before + 1, "late Blizzard load did not request a refresh")
	Assert.equal(requests[#requests], "all", "late Blizzard load requested partial work")
	Assert.equal(TimeManagerClockTicker:GetFont(), "native.ttf", "late-load refresh ran synchronously")
	env:FlushTimers()
	local _, size = TimeManagerClockTicker:GetFont()
	Assert.equal(size, addon.db.profile.clockFontSize, "late clock did not receive font styling")
	Assert.equal(#env.errors, 0, "load-on-demand lifecycle reported an error")
end

runBeforeLoginScenario()
runLoadOnDemandScenario()
_G.xpcall = nativeXpcall
print("Ace integration regressions passed")
