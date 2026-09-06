local Assertions = {}

function Assertions.equal(actual, expected, message)
	if actual ~= expected then
		error(("%s (expected %s, got %s)"):format(message or "values differ", tostring(expected), tostring(actual)), 2)
	end
end

function Assertions.truthy(value, message)
	if not value then
		error(message or "expected a truthy value", 2)
	end
	return value
end

function Assertions.raises(pattern, callback)
	local ok, err = pcall(callback)
	if ok then
		error("expected callback to raise", 2)
	end
	if pattern and not tostring(err):match(pattern) then
		error(("error %q did not match %q"):format(tostring(err), pattern), 2)
	end
	return err
end

function Assertions.point(frame, index, expected, message)
	local values = { frame:GetPoint(index) }
	for i = 1, #expected do
		if values[i] ~= expected[i] then
			error(
				("%s at value %d (expected %s, got %s)"):format(
					message or "point differs",
					i,
					tostring(expected[i]),
					tostring(values[i])
				),
				2
			)
		end
	end
end

return Assertions
