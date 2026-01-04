-- Progress_spec.lua
-- Tests for Progress domain

describe("Progress", function()
    local Progress, Result

    before_each(function()
        Progress = FenCore.Progress
        Result = FenCore.ActionResult
    end)

    describe("CalculateFill", function()
        it("should calculate fill percentage", function()
            local result = Progress.CalculateFill(75, 100)

            assert.is_true(Result.isSuccess(result))
            local data = Result.unwrap(result)
            assert.is_near(0.75, data.fillPct, 0.001)
            assert.is_false(data.isAtMax)
        end)

        it("should detect when at max", function()
            local result = Progress.CalculateFill(100, 100)
            local data = Result.unwrap(result)

            assert.is_true(data.isAtMax)
        end)

        it("should clamp to 0-1", function()
            local result = Progress.CalculateFill(150, 100)
            local data = Result.unwrap(result)

            assert.equals(1, data.fillPct)
        end)

        it("should handle negative values", function()
            local result = Progress.CalculateFill(-10, 100)
            local data = Result.unwrap(result)

            assert.equals(0, data.fillPct)
        end)

        it("should error on nil current", function()
            local result = Progress.CalculateFill(nil, 100)

            assert.is_false(Result.isSuccess(result))
            assert.equals("INVALID_INPUT", result.error.code)
        end)

        it("should use default max of 100", function()
            local result = Progress.CalculateFill(50, nil)
            local data = Result.unwrap(result)

            assert.is_near(0.5, data.fillPct, 0.001)
        end)
    end)

    describe("CalculateFillWithSessionMax", function()
        it("should use configured max when no session max", function()
            local result = Progress.CalculateFillWithSessionMax(50, 100, nil)
            local data = Result.unwrap(result)

            assert.equals(100, data.effectiveMax)
            assert.is_false(data.usedSession)
        end)

        it("should use session max when higher", function()
            local result = Progress.CalculateFillWithSessionMax(50, 100, 150)
            local data = Result.unwrap(result)

            assert.equals(150, data.effectiveMax)
            assert.is_true(data.usedSession)
        end)

        it("should ignore session max when lower", function()
            local result = Progress.CalculateFillWithSessionMax(50, 100, 80)
            local data = Result.unwrap(result)

            assert.equals(100, data.effectiveMax)
            assert.is_false(data.usedSession)
        end)

        it("should calculate fill with effective max", function()
            local result = Progress.CalculateFillWithSessionMax(75, 100, 150)
            local data = Result.unwrap(result)

            assert.is_near(0.5, data.fillPct, 0.001)
        end)
    end)

    describe("CalculateMarker", function()
        it("should calculate marker position", function()
            local result = Progress.CalculateMarker(75, 100)
            local data = Result.unwrap(result)

            assert.is_near(0.75, data.markerPct, 0.001)
            assert.is_true(data.shouldShow)
        end)

        it("should not show marker when value is 0", function()
            local result = Progress.CalculateMarker(0, 100)
            local data = Result.unwrap(result)

            assert.is_false(data.shouldShow)
        end)

        it("should not show marker when value is nil", function()
            local result = Progress.CalculateMarker(nil, 100)
            local data = Result.unwrap(result)

            assert.is_false(data.shouldShow)
        end)

        it("should clamp marker to 0-1", function()
            local result = Progress.CalculateMarker(150, 100)
            local data = Result.unwrap(result)

            assert.equals(1, data.markerPct)
        end)
    end)

    describe("ToPercentage", function()
        it("should convert to percentage", function()
            local result = Progress.ToPercentage(0.5, 1)
            local data = Result.unwrap(result)

            assert.equals(50, data.percentage)
        end)

        it("should handle different base values", function()
            local result = Progress.ToPercentage(100, 200)
            local data = Result.unwrap(result)

            assert.equals(50, data.percentage)
        end)

        it("should error on nil raw value", function()
            local result = Progress.ToPercentage(nil, 1)

            assert.is_false(Result.isSuccess(result))
        end)
    end)
end)
