local Mock = {}

local unpackValues = unpack

local function pack(...)
	return { n = select("#", ...), ... }
end

local function copyPacked(values)
	local result = { n = values.n }
	for i = 1, values.n do
		result[i] = values[i]
	end
	return result
end

local function describe(frame)
	return frame.name or frame.objectType or "anonymous frame"
end

local FrameMethods = {}

local function record(self, method, ...)
	self.calls[method] = (self.calls[method] or 0) + 1
	self.lastCall[method] = pack(...)
end

local function mutate(self, method, ...)
	if self.protected and self.env.combat then
		error(("protected mutation %s:%s during combat"):format(describe(self), method), 3)
	end
	record(self, method, ...)
end

function FrameMethods:GetObjectType()
	return self.objectType
end

function FrameMethods:IsObjectType(kind)
	return self.objectType == kind or (kind == "Region" and self.objectType == "Texture")
end

function FrameMethods:RegisterEvent(event)
	record(self, "RegisterEvent", event)
	self.events[event] = true
	return true
end

function FrameMethods:UnregisterEvent(event)
	record(self, "UnregisterEvent", event)
	self.events[event] = nil
end

function FrameMethods:UnregisterAllEvents()
	record(self, "UnregisterAllEvents")
	self.events = {}
end

function FrameMethods:IsEventRegistered(event)
	return not not self.events[event]
end

function FrameMethods:SetScript(script, callback)
	record(self, "SetScript", script, callback)
	self.scripts[script] = callback
end

function FrameMethods:GetScript(script)
	return self.scripts[script]
end

function FrameMethods:HookScript(script, callback)
	local previous = self.scripts[script]
	self.scripts[script] = function(...)
		if previous then
			previous(...)
		end
		callback(...)
	end
end

function FrameMethods:SetParent(parent)
	mutate(self, "SetParent", parent)
	self.parent = parent
end

function FrameMethods:GetParent()
	return self.parent
end

function FrameMethods:SetWidth(width)
	mutate(self, "SetWidth", width)
	self.width = width
end

function FrameMethods:SetHeight(height)
	mutate(self, "SetHeight", height)
	self.height = height
end

function FrameMethods:SetSize(width, height)
	mutate(self, "SetSize", width, height)
	self.width, self.height = width, height
end

function FrameMethods:GetWidth()
	return self.width
end

function FrameMethods:GetHeight()
	return self.height
end

function FrameMethods:ClearAllPoints()
	mutate(self, "ClearAllPoints")
	self.points = {}
end

function FrameMethods:SetPoint(...)
	mutate(self, "SetPoint", ...)
	self.points[#self.points + 1] = pack(...)
end

function FrameMethods:SetAllPoints(relative)
	mutate(self, "SetAllPoints", relative)
	self.points = { pack("ALL", relative or self.parent) }
end

function FrameMethods:GetNumPoints()
	return #self.points
end

function FrameMethods:GetPoint(index)
	local point = self.points[index or 1]
	if point then
		return unpackValues(point, 1, point.n)
	end
end

function FrameMethods:Show()
	mutate(self, "Show")
	self.shown = true
	local script = self.scripts.OnShow
	if script then
		script(self)
	end
end

function FrameMethods:Hide()
	mutate(self, "Hide")
	self.shown = false
	local script = self.scripts.OnHide
	if script then
		script(self)
	end
end

function FrameMethods:IsShown()
	return self.shown
end

function FrameMethods:IsVisible()
	return self.shown
end

function FrameMethods:SetAlpha(alpha)
	mutate(self, "SetAlpha", alpha)
	self.alpha = alpha
end

function FrameMethods:GetAlpha()
	return self.alpha
end

function FrameMethods:SetScale(scale)
	mutate(self, "SetScale", scale)
	self.scale = scale
end

function FrameMethods:GetScale()
	return self.scale
end

function FrameMethods:SetFrameStrata(strata)
	mutate(self, "SetFrameStrata", strata)
	self.frameStrata = strata
end

function FrameMethods:GetFrameStrata()
	return self.frameStrata
end

function FrameMethods:SetFrameLevel(level)
	mutate(self, "SetFrameLevel", level)
	self.frameLevel = level
end

function FrameMethods:GetFrameLevel()
	return self.frameLevel
end

function FrameMethods:SetClampedToScreen(value)
	mutate(self, "SetClampedToScreen", value)
	self.clampedToScreen = not not value
end

function FrameMethods:IsClampedToScreen()
	return self.clampedToScreen
end

function FrameMethods:SetClampRectInsets(...)
	mutate(self, "SetClampRectInsets", ...)
	self.clampRectInsets = pack(...)
end

function FrameMethods:GetClampRectInsets()
	return unpackValues(self.clampRectInsets, 1, self.clampRectInsets.n)
end

function FrameMethods:SetFont(...)
	mutate(self, "SetFont", ...)
	self.font = pack(...)
	return true
end

function FrameMethods:GetFont()
	return unpackValues(self.font, 1, self.font.n)
end

function FrameMethods:SetTextColor(...)
	mutate(self, "SetTextColor", ...)
	self.textColor = pack(...)
end

function FrameMethods:GetTextColor()
	return unpackValues(self.textColor, 1, self.textColor.n)
end

function FrameMethods:SetVertexColor(...)
	mutate(self, "SetVertexColor", ...)
	self.vertexColor = pack(...)
end

function FrameMethods:GetVertexColor()
	return unpackValues(self.vertexColor, 1, self.vertexColor.n)
end

function FrameMethods:SetTexture(texture)
	mutate(self, "SetTexture", texture)
	self.texture = texture
end

function FrameMethods:GetTexture()
	return self.texture
end

function FrameMethods:SetMaskTexture(texture)
	mutate(self, "SetMaskTexture", texture)
	self.maskTexture = texture
end

function FrameMethods:SetAtlas(atlas, useAtlasSize)
	mutate(self, "SetAtlas", atlas, useAtlasSize)
	self.atlas, self.useAtlasSize = atlas, useAtlasSize
end

function FrameMethods:GetAtlas()
	return self.atlas
end

function FrameMethods:SetTexCoord(...)
	mutate(self, "SetTexCoord", ...)
	self.texCoord = pack(...)
end

function FrameMethods:GetTexCoord()
	return unpackValues(self.texCoord, 1, self.texCoord.n)
end

function FrameMethods:SetHighlightTexture(texture)
	mutate(self, "SetHighlightTexture", texture)
	self.highlightTexture = texture
end

function FrameMethods:GetHighlightTexture()
	return self.highlightTexture
end

function FrameMethods:SetJustifyH(value)
	mutate(self, "SetJustifyH", value)
	self.justifyH = value
end

function FrameMethods:GetJustifyH()
	return self.justifyH
end

function FrameMethods:SetJustifyV(value)
	mutate(self, "SetJustifyV", value)
	self.justifyV = value
end

function FrameMethods:GetJustifyV()
	return self.justifyV
end

function FrameMethods:SetWordWrap(value)
	mutate(self, "SetWordWrap", value)
	self.wordWrap = not not value
end

function FrameMethods:CanWordWrap()
	return self.wordWrap
end

function FrameMethods:SetUseMaskTexture(value)
	mutate(self, "SetUseMaskTexture", value)
	self.useMaskTexture = not not value
end

function FrameMethods:GetUseMaskTexture()
	return self.useMaskTexture
end

for _, method in ipairs({
	"SetArchBlobRingScalar",
	"SetArchBlobRingAlpha",
	"SetQuestBlobRingScalar",
	"SetQuestBlobRingAlpha",
	"SetTaskBlobRingScalar",
	"SetTaskBlobRingAlpha",
}) do
	FrameMethods[method] = function(self, value)
		mutate(self, method, value)
		self.values[method] = value
	end
end

function FrameMethods:CreateTexture(name, layer)
	record(self, "CreateTexture", name, layer)
	return self.env:NewFrame(name, {
		objectType = "Texture",
		parent = self,
		protected = false,
		layer = layer,
	})
end

function FrameMethods:GetRegions()
	return unpackValues(self.regions, 1, self.regions.n)
end

function FrameMethods:RegisterAddon(definition)
	record(self, "RegisterAddon", definition)
	self.registeredAddon = definition
end

local frameMetatable = {
	__index = function(self, key)
		local method = FrameMethods[key]
		if method then
			return method
		end
		return nil
	end,
}

function Mock:NewFrame(name, options)
	options = options or {}
	local frame = setmetatable({
		n = false,
		env = self,
		name = name,
		objectType = options.objectType or "Frame",
		parent = options.parent,
		protected = options.protected or false,
		width = options.width or 140,
		height = options.height or 140,
		shown = options.shown ~= false,
		alpha = options.alpha or 1,
		scale = options.scale or 1,
		frameStrata = options.frameStrata or "MEDIUM",
		frameLevel = options.frameLevel or 1,
		clampedToScreen = options.clampedToScreen or false,
		clampRectInsets = options.clampRectInsets or pack(0, 0, 0, 0),
		font = options.font or pack("native.ttf", 12, ""),
		textColor = options.textColor or pack(0.1, 1, 0.1, 1),
		vertexColor = options.vertexColor or pack(1, 1, 1, 1),
		texture = options.texture,
		maskTexture = options.maskTexture or "native-mask",
		texCoord = options.texCoord or pack(0, 1, 0, 1),
		justifyH = options.justifyH or "LEFT",
		justifyV = options.justifyV or "TOP",
		wordWrap = options.wordWrap ~= false,
		useMaskTexture = options.useMaskTexture ~= false,
		points = options.points or {},
		regions = options.regions or { n = 0 },
		events = {},
		scripts = {},
		calls = {},
		lastCall = {},
		values = {},
	}, frameMetatable)
	if frame.objectType == "Texture" then
		frame.SetFont = false
		frame.GetFont = false
		frame.SetTextColor = false
		frame.GetTextColor = false
		frame.SetFrameStrata = false
		frame.GetFrameStrata = false
		frame.SetFrameLevel = false
		frame.GetFrameLevel = false
		frame.RegisterEvent = false
		frame.UnregisterEvent = false
		frame.UnregisterAllEvents = false
		frame.CreateTexture = false
	elseif frame.objectType == "FontString" then
		frame.SetFrameStrata = false
		frame.GetFrameStrata = false
		frame.SetFrameLevel = false
		frame.GetFrameLevel = false
		frame.RegisterEvent = false
		frame.UnregisterEvent = false
		frame.UnregisterAllEvents = false
		frame.CreateTexture = false
		frame.SetParent = false
	end
	self.frames[#self.frames + 1] = frame
	if name then
		_G[name] = frame
	end
	return frame
end

function Mock:SetCombat(value)
	self.combat = not not value
end

function Mock:SetLoggedIn(value)
	self.loggedIn = not not value
end

function Mock:FlushTimers(maxRounds)
	maxRounds = maxRounds or 50
	local rounds = 0
	while #self.timers > 0 do
		rounds = rounds + 1
		assert(rounds <= maxRounds, "timer queue did not settle")
		local pending = self.timers
		self.timers = {}
		for _, timer in ipairs(pending) do
			if not timer.cancelled then
				timer.callback()
			end
		end
	end
	return rounds
end

function Mock:FireEvent(event, ...)
	local frames = {}
	for _, frame in ipairs(self.frames) do
		if frame.events[event] and frame.scripts.OnEvent then
			frames[#frames + 1] = frame
		end
	end
	for _, frame in ipairs(frames) do
		if frame.events[event] and frame.scripts.OnEvent then
			frame.scripts.OnEvent(frame, event, ...)
		end
	end
end

function Mock:ResetCounts()
	for _, frame in ipairs(self.frames) do
		frame.calls = {}
		frame.lastCall = {}
	end
end

function Mock:Install(options)
	options = options or {}
	self.frames = {}
	self.timers = {}
	self.errors = {}
	self.combat = options.combat or false
	self.loggedIn = options.loggedIn ~= false
	self.profileClock = 0
	self.nativeZoneColor = pack(0.1, 1, 0.1, 1)

	_G.strmatch = string.match
	_G.strsub = string.sub
	_G.strlower = string.lower
	_G.strtrim = function(value)
		return (value:gsub("^%s+", ""):gsub("%s+$", ""))
	end
	_G.format = string.format
	_G.tinsert = table.insert
	_G.tremove = table.remove
	_G.wipe = function(tbl)
		for key in pairs(tbl) do
			tbl[key] = nil
		end
		return tbl
	end
	_G.securecallfunction = function(callback, ...)
		return callback(...)
	end
	_G.geterrorhandler = function()
		return function(err)
			self.errors[#self.errors + 1] = tostring(err)
		end
	end
	_G.debugprofilestop = function()
		self.profileClock = self.profileClock + 1
		return self.profileClock
	end
	_G.InCombatLockdown = function()
		return self.combat
	end
	_G.IsLoggedIn = function()
		return self.loggedIn
	end
	_G.GetRealmName = function()
		return "Test Realm"
	end
	_G.UnitName = function()
		return "Tester"
	end
	_G.UnitClass = function()
		return "Mage", "MAGE"
	end
	_G.UnitRace = function()
		return "Human", "Human"
	end
	_G.UnitFactionGroup = function()
		return "Alliance"
	end
	_G.GetLocale = function()
		return "enUS"
	end
	_G.GetCurrentRegion = function()
		return 1
	end
	_G.GetCurrentRegionName = function()
		return "US"
	end
	_G.CreateFrame = function(_, name, parent)
		return self:NewFrame(name, { parent = parent })
	end
	_G.C_Timer = {
		After = function(_, callback)
			local timer = { callback = callback, cancelled = false }
			self.timers[#self.timers + 1] = timer
			return timer
		end,
	}
	_G.hooksecurefunc = function(target, method, callback)
		if type(target) == "string" then
			callback, method, target = method, target, _G
		end
		local original = assert(target[method], "cannot hook missing method " .. tostring(method))
		target[method] = function(...)
			local results = pack(original(...))
			callback(...)
			return unpackValues(results, 1, results.n)
		end
	end

	local nativeParent = self:NewFrame("NativeMinimapParent")
	_G.MinimapCluster = self:NewFrame("MinimapCluster", {
		parent = nativeParent,
		protected = true,
		points = { pack("TOPRIGHT", nativeParent, "TOPRIGHT", -20, -20) },
	})
	_G.Minimap = self:NewFrame("Minimap", {
		parent = MinimapCluster,
		protected = true,
		points = { pack("CENTER", MinimapCluster, "CENTER", 3, 4) },
	})
	Minimap.ZoomIn = self:NewFrame("MinimapZoomIn", { parent = Minimap, protected = true })
	Minimap.ZoomOut = self:NewFrame("MinimapZoomOut", { parent = Minimap, protected = true })
	MinimapCluster.ZoneTextButton = self:NewFrame("MinimapClusterZoneTextButton", {
		parent = MinimapCluster,
		protected = true,
		points = { pack("TOP", MinimapCluster, "TOP", 5, -6) },
	})
	MinimapCluster.Tracking = self:NewFrame("MinimapClusterTracking", {
		parent = MinimapCluster,
		protected = true,
	})
	MinimapCluster.InstanceDifficulty = self:NewFrame("MinimapClusterInstanceDifficulty", {
		parent = MinimapCluster,
		protected = true,
	})
	MinimapCluster.BorderTop = self:NewFrame("MinimapClusterBorderTop", {
		parent = MinimapCluster,
		protected = true,
	})
	_G.MinimapZoneText = self:NewFrame("MinimapZoneText", {
		objectType = "FontString",
		parent = MinimapCluster.ZoneTextButton,
		protected = true,
	})
	_G.MinimapCompassTexture = self:NewFrame("MinimapCompassTexture", {
		objectType = "Texture",
		parent = Minimap,
		protected = true,
	})
	_G.GameTimeFrame = self:NewFrame("GameTimeFrame", { parent = MinimapCluster, protected = true })
	_G.AddonCompartmentFrame = self:NewFrame("AddonCompartmentFrame", {
		parent = MinimapCluster,
		protected = true,
	})
	_G.ExpansionLandingPageMinimapButton = self:NewFrame("ExpansionLandingPageMinimapButton", {
		parent = MinimapCluster,
		protected = true,
	})
	_G.TimeManagerClockButton = nil
	_G.TimeManagerClockTicker = nil
	_G.HybridMinimap = nil
	_G.ExpansionLandingPage = nil
	_G.C_Texture = {
		GetAtlasInfo = function()
			return true
		end,
	}
	_G.GameTooltip = {
		SetOwner = function() end,
		AddLine = function() end,
		Show = function() end,
		Hide = function() end,
	}
	_G.ToggleEncounterJournal = function() end
	_G.GetMinimapShape = function()
		return "ROUND"
	end
	_G.Minimap_Update = function()
		MinimapZoneText:SetTextColor(unpackValues(self.nativeZoneColor, 1, self.nativeZoneColor.n))
	end

	_G.DEFAULT_CHAT_FRAME = {
		messages = {},
		AddMessage = function(frame, message)
			frame.messages[#frame.messages + 1] = message
		end,
	}
	_G.SlashCmdList = {}
	_G.hash_SlashCmdList = {}

	return self
end

function Mock.new(options)
	local instance = setmetatable({}, { __index = Mock })
	return instance:Install(options)
end

Mock.pack = pack
Mock.copyPacked = copyPacked

return Mock
