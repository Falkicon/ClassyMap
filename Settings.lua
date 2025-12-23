local addonName, ns = ...
local L = LibStub("AceLocale-3.0"):GetLocale("ClassyMap")
local Settings = {}
ns.Settings = Settings

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- =============================================================================
-- Options Table
-- =============================================================================
local function GetOptions()
	local ClassyMap = ns.ClassyMap

	return {
		name = L["ClassyMap"],
		type = "group",
		args = {
			header = {
				type = "description",
				name = L["A minimalist square minimap with a simple border and button drawer.\n"],
				fontSize = "medium",
				order = 0,
			},
			enabled = {
				type = "toggle",
				name = L["Enable ClassyMap"],
				desc = L["Toggle the square minimap on/off."],
				width = "full",
				order = 1,
				get = function()
					return ClassyMap.db.profile.enabled
				end,
				set = function(_, val)
					ClassyMap.db.profile.enabled = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},

			-- Border Settings
			borderHeader = {
				type = "header",
				name = L["Border"],
				order = 10,
			},
			borderSize = {
				type = "range",
				name = L["Border Size"],
				desc = L["Thickness of the minimap border. Set to 0 to hide."],
				min = 0,
				max = 8,
				step = 1,
				order = 11,
				get = function()
					return ClassyMap.db.profile.borderSize
				end,
				set = function(_, val)
					ClassyMap.db.profile.borderSize = val
					ClassyMap:UpdateBorderStyle()
				end,
			},
			borderColor = {
				type = "color",
				name = L["Border Color"],
				desc = L["Color of the minimap border."],
				hasAlpha = true,
				order = 12,
				get = function()
					local c = ClassyMap.db.profile.borderColor
					return c.r, c.g, c.b, c.a
				end,
				set = function(_, r, g, b, a)
					ClassyMap.db.profile.borderColor = { r = r, g = g, b = b, a = a }
					ClassyMap:UpdateBorderStyle()
				end,
			},

			-- Fonts
			fontHeader = {
				type = "header",
				name = L["Fonts"],
				order = 17,
			},
			font = {
				type = "select",
				dialogControl = "LSM30_Font",
				name = L["Font Face"],
				order = 17.5,
				values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
				get = function()
					return ClassyMap.db.profile.font
				end,
				set = function(_, val)
					ClassyMap.db.profile.font = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			zoneFontSize = {
				type = "range",
				name = L["Zone Text Size"],
				min = 6,
				max = 16,
				step = 1,
				order = 18,
				get = function()
					return ClassyMap.db.profile.zoneFontSize
				end,
				set = function(_, val)
					ClassyMap.db.profile.zoneFontSize = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			overrideZoneColor = {
				type = "toggle",
				name = L["Override Blizzard Zone Color"],
				desc = L["If checked, use the custom color below. If unchecked, use Blizzard's default colors (Blue for Sanctuary, Red for PVP, etc)."],
				order = 18.5,
				width = "full",
				get = function()
					return ClassyMap.db.profile.overrideZoneColor
				end,
				set = function(_, val)
					ClassyMap.db.profile.overrideZoneColor = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			zoneTextColor = {
				type = "color",
				name = L["Zone Text Color"],
				hasAlpha = true,
				order = 19,
				get = function()
					local c = ClassyMap.db.profile.zoneTextColor
					return c.r, c.g, c.b, c.a
				end,
				set = function(_, r, g, b, a)
					ClassyMap.db.profile.zoneTextColor = { r = r, g = g, b = b, a = a }
					ClassyMap:ApplyMinimapChanges()
				end,
				disabled = function()
					return not ClassyMap.db.profile.overrideZoneColor
				end,
			},
			clockFontSize = {
				type = "range",
				name = L["Clock Text Size"],
				min = 6,
				max = 16,
				step = 1,
				order = 20,
				get = function()
					return ClassyMap.db.profile.clockFontSize
				end,
				set = function(_, val)
					ClassyMap.db.profile.clockFontSize = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			clockTextColor = {
				type = "color",
				name = L["Clock Text Color"],
				hasAlpha = true,
				order = 21,
				get = function()
					local c = ClassyMap.db.profile.clockTextColor
					return c.r, c.g, c.b, c.a
				end,
				set = function(_, r, g, b, a)
					ClassyMap.db.profile.clockTextColor = { r = r, g = g, b = b, a = a }
					ClassyMap:ApplyMinimapChanges()
				end,
			},

			-- Hide Elements
			-- Hide Elements
			hideHeader = {
				type = "header",
				name = L["Hide Elements"],
				order = 30,
			},

			-- Priority Items (Top Right Cluster)
			hideTracking = {
				type = "toggle",
				name = L["Hide Tracking"],
				order = 31,
				get = function()
					return ClassyMap.db.profile.hideTracking
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideTracking = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},

			-- Text Elements
			hideZoneText = {
				type = "toggle",
				name = L["Hide Zone Text"],
				order = 32,
				get = function()
					return ClassyMap.db.profile.hideZoneText
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideZoneText = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			hideClock = {
				type = "toggle",
				name = L["Hide Clock"],
				desc = L["Hide the time display."],
				order = 33,
				get = function()
					return ClassyMap.db.profile.hideClock
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideClock = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},

			-- Map Controls
			hideZoomButtons = {
				type = "toggle",
				name = L["Hide Zoom Buttons"],
				desc = L["Hide the minimap zoom in/out buttons."],
				order = 34,
				get = function()
					return ClassyMap.db.profile.hideZoomButtons
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideZoomButtons = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			hideExpansionButton = {
				type = "toggle",
				name = L["Hide Expansion Button"],
				desc = L["Hide the large expansion button and replace with a smaller icon."],
				order = 35,
				get = function()
					return ClassyMap.db.profile.hideExpansionButton
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideExpansionButton = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			-- Custom Icon Input removed as per request (Hardcoded)

			-- Drawer Buttons
			hideCalendar = {
				type = "toggle",
				name = L["Hide Calendar"],
				order = 36,
				get = function()
					return ClassyMap.db.profile.hideCalendar
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideCalendar = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			hideAddonBtn = {
				type = "toggle",
				name = L["Hide Addon Drawer"],
				order = 37,
				get = function()
					return ClassyMap.db.profile.hideAddonBtn
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideAddonBtn = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
			hideInstance = {
				type = "toggle",
				name = L["Hide Instance Difficulty"],
				order = 38,
				get = function()
					return ClassyMap.db.profile.hideInstance
				end,
				set = function(_, val)
					ClassyMap.db.profile.hideInstance = val
					ClassyMap:ApplyMinimapChanges()
				end,
			},
		},
	}
end

-- =============================================================================
-- Registration
-- =============================================================================
function Settings:Initialize()
	AceConfig:RegisterOptionsTable("ClassyMap", GetOptions)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("ClassyMap", "ClassyMap")
end

function Settings:OpenOptions()
	-- Ensure registered
	if not self.optionsFrame then
		self:Initialize()
	end

	-- Open standalone dialog
	AceConfigDialog:Open("ClassyMap")
end

-- Auto-init on addon load
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
	if addon == addonName then
		Settings:Initialize()
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
