-- ClassyMap Core Layer
-- Pure Lua logic with no WoW API dependencies (sandbox-compatible)

-- FenCore integration for pure logic
local FenCore = _G.FenCore
local Math = FenCore and FenCore.Math
local unpackArgs = table.unpack or unpack

-- Delegate to FenCore.Math.Clamp with fallback
local Clamp = Math and Math.Clamp
	or function(n, minV, maxV)
		if n < minV then
			return minV
		end
		if n > maxV then
			return maxV
		end
		return n
	end

---@class ClassyMapCore
ClassyMapCore = ClassyMapCore or {}

-- =============================================================================
-- Combat Queue
-- Stores actions to execute when combat ends (no WoW dependencies here)
-- =============================================================================

ClassyMapCore.combatQueue = ClassyMapCore.combatQueue or {}

local function ClearTable(tbl)
	-- Use wipe if available (WoW), otherwise standard Lua clear.
	if table.wipe then
		table.wipe(tbl)
	else
		for key in pairs(tbl) do
			tbl[key] = nil
		end
	end
end

--- Queue an action for later execution
---@param func function The function to execute
---@param args table|nil Optional arguments to pass
function ClassyMapCore:QueueAction(func, args)
	assert(type(func) == "function", "QueueAction requires a function")
	assert(args == nil or type(args) == "table", "QueueAction args must be a table or nil")

	args = args or {}
	if args.n == nil then
		args.n = #args
	end
	assert(
		type(args.n) == "number"
			and args.n == args.n
			and args.n ~= math.huge
			and args.n >= 0
			and args.n == math.floor(args.n),
		"QueueAction args.n must be a non-negative integer"
	)

	table.insert(self.combatQueue, { func = func, args = args })
end

--- Process the actions that are currently queued
--- Actions queued by a callback remain queued for the next drain.
---@param onError function|nil Optional error reporter called for each failed action
---@return number processed Number of actions processed
---@return number failed Number of actions that failed
function ClassyMapCore:ProcessQueue(onError)
	assert(onError == nil or type(onError) == "function", "ProcessQueue error handler must be a function or nil")

	local queue = self.combatQueue
	self.combatQueue = {}
	local processed = 0
	local failed = 0
	for _, item in ipairs(queue) do
		local args = item.args
		local success, err = pcall(item.func, unpackArgs(args, 1, args.n or #args))
		processed = processed + 1
		if not success then
			failed = failed + 1
			if onError then
				-- An error reporter must not prevent the remaining actions from running.
				pcall(onError, err)
			end
		end
	end
	ClearTable(queue)
	return processed, failed
end

--- Get the current queue length
---@return number length Number of queued actions
function ClassyMapCore:GetQueueLength()
	return #self.combatQueue
end

--- Clear the queue without processing
function ClassyMapCore:ClearQueue()
	ClearTable(self.combatQueue)
end

-- =============================================================================
-- Settings Validation
-- Pure validation logic for settings values
-- =============================================================================

local function IsFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function ValidateChannel(value)
	value = tonumber(value)
	if not IsFiniteNumber(value) then
		return 1
	end
	return Clamp(value, 0, 1)
end

--- Validate border size setting
---@param size number|nil The border size to validate
---@return number validSize Clamped border size (0-8)
function ClassyMapCore:ValidateBorderSize(size)
	if not IsFiniteNumber(size) then
		return 1 -- default
	end
	return Clamp(math.floor(size), 0, 8)
end

--- Validate font size setting
---@param size number|nil The font size to validate
---@return number validSize Clamped font size (6-24)
function ClassyMapCore:ValidateFontSize(size)
	if not IsFiniteNumber(size) then
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
		r = ValidateChannel(color.r),
		g = ValidateChannel(color.g),
		b = ValidateChannel(color.b),
		a = ValidateChannel(color.a),
	}
end

return ClassyMapCore
