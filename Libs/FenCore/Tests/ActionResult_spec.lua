-- ActionResult_spec.lua
-- Tests for the AFD result pattern

describe("ActionResult", function()
    local Result

    before_each(function()
        -- FenCore namespace is set up by sandbox
        Result = FenCore.ActionResult
    end)

    describe("success", function()
        it("should create a successful result", function()
            local result = Result.success({ value = 42 })

            assert.is_true(result.success)
            assert.same({ value = 42 }, result.data)
            assert.is_nil(result.error)
        end)

        it("should include reasoning when provided", function()
            local result = Result.success({ x = 1 }, "Calculated from input")

            assert.equals("Calculated from input", result.reasoning)
        end)
    end)

    describe("error", function()
        it("should create an error result", function()
            local result = Result.error("INVALID_INPUT", "Value must be positive")

            assert.is_false(result.success)
            assert.is_nil(result.data)
            assert.equals("INVALID_INPUT", result.error.code)
            assert.equals("Value must be positive", result.error.message)
        end)

        it("should include suggestion when provided", function()
            local result = Result.error("NOT_FOUND", "Item not found", "Check the ID")

            assert.equals("Check the ID", result.error.suggestion)
        end)
    end)

    describe("isSuccess", function()
        it("should return true for success results", function()
            local result = Result.success({})
            assert.is_true(Result.isSuccess(result))
        end)

        it("should return false for error results", function()
            local result = Result.error("ERR", "msg")
            assert.is_false(Result.isSuccess(result))
        end)

        it("should return false for nil", function()
            assert.is_false(Result.isSuccess(nil))
        end)
    end)

    describe("isError", function()
        it("should return true for error results", function()
            local result = Result.error("ERR", "msg")
            assert.is_true(Result.isError(result))
        end)

        it("should return false for success results", function()
            local result = Result.success({})
            assert.is_false(Result.isError(result))
        end)
    end)

    describe("unwrap", function()
        it("should return data from success result", function()
            local result = Result.success({ answer = 42 })
            local data = Result.unwrap(result)

            assert.equals(42, data.answer)
        end)

        it("should return nil from error result", function()
            local result = Result.error("ERR", "msg")
            assert.is_nil(Result.unwrap(result))
        end)
    end)

    describe("getErrorCode", function()
        it("should return error code from error result", function()
            local result = Result.error("INVALID_INPUT", "msg")
            assert.equals("INVALID_INPUT", Result.getErrorCode(result))
        end)

        it("should return nil from success result", function()
            local result = Result.success({})
            assert.is_nil(Result.getErrorCode(result))
        end)
    end)

    describe("map", function()
        it("should transform successful data", function()
            local result = Result.success({ value = 10 })
            local mapped = Result.map(result, function(data)
                return { doubled = data.value * 2 }
            end)

            assert.is_true(mapped.success)
            assert.equals(20, mapped.data.doubled)
        end)

        it("should pass through error results", function()
            local result = Result.error("ERR", "original")
            local mapped = Result.map(result, function(data)
                return { transformed = true }
            end)

            assert.is_false(mapped.success)
            assert.equals("original", mapped.error.message)
        end)
    end)
end)
