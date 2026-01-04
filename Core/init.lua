-- ClassyMap Core Layer
-- Pure Lua logic with no WoW API dependencies (sandbox-compatible)

-- FenCore integration for pure logic
local FenCore = _G.FenCore
local Math = FenCore and FenCore.Math

-- Delegate to FenCore.Math.Clamp with fallback
local Clamp = Math and Math.Clamp or function(n, minV, maxV)
	if n < minV then return minV end
	if n > maxV then return maxV end
	return n
end

---@class ClassyMapCore
ClassyMapCore = ClassyMapCore or {}

-- =============================================================================
-- Combat Queue
-- Stores actions to execute when combat ends (no WoW dependencies here)
-- =============================================================================

ClassyMapCore.combatQueue = {}

--- Queue an action for later execution
---@param func function The function to execute
---@param args table|nil Optional arguments to pass
function ClassyMapCore:QueueAction(func, args)
	table.insert(self.combatQueue, { func = func, args = args or {} })
end

--- Process all queued actions and clear the queue
---@return number processed Number of actions processed
function ClassyMapCore:ProcessQueue()
	local processed = 0
	for _, item in ipairs(self.combatQueue) do
		item.func(unpack(item.args))
		processed = processed + 1
	end
	-- Use wipe if available (WoW), otherwise standard Lua clear
	if table.wipe then
		table.wipe(self.combatQueue)
	else
		for k in pairs(self.combatQueue) do
			self.combatQueue[k] = nil
		end
	end
	return processed
end

--- Get the current queue length
---@return number length Number of queued actions
function ClassyMapCore:GetQueueLength()
	return #self.combatQueue
end

--- Clear the queue without processing
function ClassyMapCore:ClearQueue()
	-- Use wipe if available (WoW), otherwise standard Lua clear
	if table.wipe then
		table.wipe(self.combatQueue)
	else
		for k in pairs(self.combatQueue) do
			self.combatQueue[k] = nil
		end
	end
end

-- =============================================================================
-- Settings Validation
-- Pure validation logic for settings values
-- =============================================================================

--- Validate border size setting
---@param size number|nil The border size to validate
---@return number validSize Clamped border size (0-8)
function ClassyMapCore:ValidateBorderSize(size)
	if type(size) ~= "number" then
		return 1 -- default
	end
	return Clamp(math.floor(size), 0, 8)
end

--- Validate font size setting
---@param size number|nil The font size to validate
---@return number validSize Clamped font size (6-24)
function ClassyMapCore:ValidateFontSize(size)
	if type(size) ~= "number" then
		return 11 -- default
	end
	return Clamp(math.floor(size), 6, 24)
end

--- Validate color table
---@param color table|nil The color table to validate
---@return table validColor A valid color table with r,g,b,a
function ClassyMapCore:ValidateColor(color)
	if type(color) ~= "table" then
		return { r = 1, g = 1, b = 1, a = 1 }
	end
	return {
		r = Clamp(tonumber(color.r) or 1, 0, 1),
		g = Clamp(tonumber(color.g) or 1, 0, 1),
		b = Clamp(tonumber(color.b) or 1, 0, 1),
		a = Clamp(tonumber(color.a) or 1, 0, 1),
	}
end

return ClassyMapCore
