-- ClassyMap Core Tests
-- Sandbox-compatible tests for pure Lua logic

describe("ClassyMap Core", function()
	describe("Combat Queue", function()
		before_each(function()
			ClassyMapCore.combatQueue = {}
		end)

		it("should start with empty queue", function()
			assert.equals(0, ClassyMapCore:GetQueueLength())
		end)

		it("should queue a single action", function()
			ClassyMapCore:QueueAction(function() end, {})
			assert.equals(1, ClassyMapCore:GetQueueLength())
		end)

		it("should queue multiple actions", function()
			ClassyMapCore:QueueAction(function() end, {})
			ClassyMapCore:QueueAction(function() end, {})
			ClassyMapCore:QueueAction(function() end, {})
			assert.equals(3, ClassyMapCore:GetQueueLength())
		end)

		it("should process and clear queue", function()
			local count = 0
			ClassyMapCore:QueueAction(function()
				count = count + 1
			end, {})
			ClassyMapCore:QueueAction(function()
				count = count + 1
			end, {})

			local processed = ClassyMapCore:ProcessQueue()
			assert.equals(2, processed)
			assert.equals(0, ClassyMapCore:GetQueueLength())
			assert.equals(2, count)
		end)

		it("should pass arguments to queued functions", function()
			local result = nil
			ClassyMapCore:QueueAction(function(a, b)
				result = a + b
			end, { 10, 20 })

			ClassyMapCore:ProcessQueue()
			assert.equals(30, result)
		end)

		it("should clear queue without processing", function()
			local called = false
			ClassyMapCore:QueueAction(function()
				called = true
			end, {})

			ClassyMapCore:ClearQueue()
			assert.equals(0, ClassyMapCore:GetQueueLength())
			assert.is_false(called)
		end)
	end)

	describe("Settings Validation", function()
		describe("ValidateBorderSize", function()
			it("should return default for nil", function()
				assert.equals(1, ClassyMapCore:ValidateBorderSize(nil))
			end)

			it("should return default for non-number", function()
				assert.equals(1, ClassyMapCore:ValidateBorderSize("abc"))
			end)

			it("should clamp to minimum 0", function()
				assert.equals(0, ClassyMapCore:ValidateBorderSize(-5))
			end)

			it("should clamp to maximum 8", function()
				assert.equals(8, ClassyMapCore:ValidateBorderSize(20))
			end)

			it("should accept valid values", function()
				assert.equals(0, ClassyMapCore:ValidateBorderSize(0))
				assert.equals(4, ClassyMapCore:ValidateBorderSize(4))
				assert.equals(8, ClassyMapCore:ValidateBorderSize(8))
			end)

			it("should floor decimal values", function()
				assert.equals(2, ClassyMapCore:ValidateBorderSize(2.7))
			end)
		end)

		describe("ValidateFontSize", function()
			it("should return default for nil", function()
				assert.equals(11, ClassyMapCore:ValidateFontSize(nil))
			end)

			it("should clamp to minimum 6", function()
				assert.equals(6, ClassyMapCore:ValidateFontSize(2))
			end)

			it("should clamp to maximum 24", function()
				assert.equals(24, ClassyMapCore:ValidateFontSize(50))
			end)

			it("should accept valid values", function()
				assert.equals(10, ClassyMapCore:ValidateFontSize(10))
				assert.equals(16, ClassyMapCore:ValidateFontSize(16))
			end)
		end)

		describe("ValidateColor", function()
			it("should return white for nil", function()
				local color = ClassyMapCore:ValidateColor(nil)
				assert.equals(1, color.r)
				assert.equals(1, color.g)
				assert.equals(1, color.b)
				assert.equals(1, color.a)
			end)

			it("should clamp values to 0-1 range", function()
				local color = ClassyMapCore:ValidateColor({ r = -1, g = 2, b = 0.5, a = 1.5 })
				assert.equals(0, color.r)
				assert.equals(1, color.g)
				assert.equals(0.5, color.b)
				assert.equals(1, color.a)
			end)

			it("should handle missing fields", function()
				local color = ClassyMapCore:ValidateColor({ r = 0.5 })
				assert.equals(0.5, color.r)
				assert.equals(1, color.g) -- default
				assert.equals(1, color.b) -- default
				assert.equals(1, color.a) -- default
			end)
		end)
	end)
end)
