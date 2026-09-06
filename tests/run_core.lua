-- Minimal standalone runner for Core/core_spec.lua.
-- This keeps the pure Core suite runnable with Lua 5.1 when Busted is unavailable.

local nativeAssert = assert
local contexts = {}
local failures = 0
local tests = 0

local assertions = {}
setmetatable(assertions, {
	__call = function(_, ...)
		return nativeAssert(...)
	end,
})

function assertions.equals(expected, actual)
	nativeAssert(actual == expected, ("expected %s, got %s"):format(tostring(expected), tostring(actual)))
end

function assertions.is_false(value)
	nativeAssert(value == false, "expected false")
end

function assertions.is_true(value)
	nativeAssert(value == true, "expected true")
end

function assertions.is_nil(value)
	nativeAssert(value == nil, ("expected nil, got %s"):format(tostring(value)))
end

function assertions.is_truthy(value)
	nativeAssert(value, "expected a truthy value")
end

function assertions.has_error(func, expected)
	local success, err = pcall(func)
	nativeAssert(not success, "expected an error")
	err = tostring(err)
	nativeAssert(err:sub(-#expected) == expected, ("expected error %q, got %q"):format(expected, err))
end

_G.assert = assertions

function _G.describe(_, body)
	local context = { beforeEach = {} }
	table.insert(contexts, context)
	body()
	table.remove(contexts)
end

function _G.before_each(callback)
	table.insert(contexts[#contexts].beforeEach, callback)
end

function _G.it(name, body)
	tests = tests + 1
	local success, err = pcall(function()
		for _, context in ipairs(contexts) do
			for _, callback in ipairs(context.beforeEach) do
				callback()
			end
		end
		body()
	end)
	if not success then
		failures = failures + 1
		io.stderr:write(("FAIL: %s\n%s\n"):format(name, tostring(err)))
	end
end

if arg[1] == "--fencore" then
	-- Load the bundled pure domain and its real registry without WoW bootstrap code.
	_G.FenCore = { Log = function() end }
	dofile("Libs/FenCore/Core/Catalog.lua")
	dofile("Libs/FenCore/Domains/Math.lua")
end
dofile("Core/init.lua")
dofile("Core/core_spec.lua")

if failures > 0 then
	error(("%d of %d core tests failed"):format(failures, tests), 0)
end

print(("Core: %d tests passed"):format(tests))
