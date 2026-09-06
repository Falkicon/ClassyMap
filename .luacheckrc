-- ClassyMap Luacheck configuration.
--
-- Use the shared configuration when this repository is checked out beside
-- ADDON_DEV. Keep a small fallback here so a standalone clone can still run
-- Luacheck without requiring the wider development workspace.

local function add_unique(list, value)
	for _, existing in ipairs(list) do
		if existing == value then
			return
		end
	end
	table.insert(list, value)
end

local addon_globals = {
	"ClassyMap",
	"ClassyMapDB",
	"ClassyMapCore",
	"ClassyMapMechanic",
	"GetMinimapShape",
}

-- WoW frames and APIs referenced by the minimap integration. Keeping this
-- list explicit preserves Luacheck's useful undefined-global warnings.
local addon_read_globals = {
	"AddonCompartmentFrame",
	"C_AddOns",
	"C_Texture",
	"C_Timer",
	"CreateFrame",
	"debugprofilestop",
	"ExpansionLandingPage",
	"ExpansionLandingPageMinimapButton",
	"GameTimeFrame",
	"GameTooltip",
	"GetTime",
	"geterrorhandler",
	"hooksecurefunc",
	"HybridMinimap",
	"InCombatLockdown",
	"IsLoggedIn",
	"Minimap",
	"MinimapCluster",
	"MinimapCompassTexture",
	"Minimap_Update",
	"MinimapZoneText",
	"TimeManagerClockButton",
	"TimeManagerClockTicker",
	"ToggleEncounterJournal",
}

local ok, shared = pcall(dofile, "../ADDON_DEV/Linting/.luacheckrc")
local base = ok and type(shared) == "table" and shared or {
	std = "lua51",
	max_line_length = false,
	codes = true,
	quiet = 1,
	exclude_files = {
		"**/Libs/**",
		"**/*_spec.lua",
		"tests/**",
		".luacheckrc",
	},
	globals = { "_G", "SlashCmdList" },
	read_globals = {
		"LibStub",
		"wipe",
		table = { fields = { "unpack", "wipe" } },
	},
	ignore = {
		"212/self",
		"212/_.*",
		"631",
	},
}

std = base.std
max_line_length = base.max_line_length
codes = base.codes
quiet = base.quiet
exclude_files = base.exclude_files or {}
globals = base.globals or {}
read_globals = base.read_globals or {}
ignore = base.ignore or {}

for _, name in ipairs(addon_globals) do
	add_unique(globals, name)
end

for _, name in ipairs(addon_read_globals) do
	add_unique(read_globals, name)
end

-- Busted-style specs live beside the pure Core implementation and are not
-- first-party addon runtime code.
add_unique(exclude_files, "**/*_spec.lua")
