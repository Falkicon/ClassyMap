-- Math_spec.lua
-- Tests for Math domain

describe("Math", function()
    local Math

    before_each(function()
        Math = FenCore.Math
    end)

    describe("Clamp", function()
        it("should return value when within range", function()
            assert.equals(50, Math.Clamp(50, 0, 100))
        end)

        it("should return min when below range", function()
            assert.equals(0, Math.Clamp(-10, 0, 100))
        end)

        it("should return max when above range", function()
            assert.equals(100, Math.Clamp(150, 0, 100))
        end)

        it("should handle edge cases", function()
            assert.equals(0, Math.Clamp(0, 0, 100))
            assert.equals(100, Math.Clamp(100, 0, 100))
        end)
    end)

    describe("Lerp", function()
        it("should return start at t=0", function()
            assert.equals(0, Math.Lerp(0, 100, 0))
        end)

        it("should return end at t=1", function()
            assert.equals(100, Math.Lerp(0, 100, 1))
        end)

        it("should return midpoint at t=0.5", function()
            assert.equals(50, Math.Lerp(0, 100, 0.5))
        end)

        it("should clamp t to 0-1", function()
            assert.equals(0, Math.Lerp(0, 100, -0.5))
            assert.equals(100, Math.Lerp(0, 100, 1.5))
        end)
    end)

    describe("SmoothDelta", function()
        it("should smooth between old and new values", function()
            local result = Math.SmoothDelta(10, 20, 0.5)
            assert.equals(15, result)
        end)

        it("should use default weight of 0.7", function()
            local result = Math.SmoothDelta(10, 20)
            assert.is_near(13, result, 0.001)
        end)
    end)

    describe("ToFraction", function()
        it("should calculate fraction correctly", function()
            assert.is_near(0.75, Math.ToFraction(75, 100), 0.001)
        end)

        it("should clamp to 0-1", function()
            assert.equals(0, Math.ToFraction(-10, 100))
            assert.equals(1, Math.ToFraction(150, 100))
        end)

        it("should handle zero max", function()
            assert.equals(0, Math.ToFraction(50, 0))
        end)
    end)

    describe("ToPercentage", function()
        it("should calculate percentage correctly", function()
            assert.equals(75, Math.ToPercentage(75, 100))
        end)

        it("should handle zero max", function()
            assert.equals(0, Math.ToPercentage(50, 0))
        end)
    end)

    describe("NormalizeDelta", function()
        it("should normalize to -1 to 1 range", function()
            assert.equals(0.5, Math.NormalizeDelta(5, 10))
            assert.equals(-0.5, Math.NormalizeDelta(-5, 10))
        end)

        it("should clamp to range", function()
            assert.equals(1, Math.NormalizeDelta(20, 10))
            assert.equals(-1, Math.NormalizeDelta(-20, 10))
        end)
    end)

    describe("Round", function()
        it("should round to nearest integer by default", function()
            assert.equals(3, Math.Round(3.4))
            assert.equals(4, Math.Round(3.5))
        end)

        it("should round to specified decimals", function()
            assert.is_near(3.14, Math.Round(3.14159, 2), 0.001)
        end)
    end)

    describe("MapRange", function()
        it("should map value between ranges", function()
            assert.equals(0.5, Math.MapRange(50, {inMin=0, inMax=100, outMin=0, outMax=1}))
        end)

        it("should handle inverse mapping", function()
            assert.equals(75, Math.MapRange(0.25, {inMin=0, inMax=1, outMin=100, outMax=0}))
        end)

        it("should handle same input range", function()
            assert.equals(0, Math.MapRange(50, {inMin=100, inMax=100, outMin=0, outMax=1}))
        end)

        it("should use sensible defaults", function()
            -- Default ranges are 0-1 for both input and output
            assert.equals(0.5, Math.MapRange(0.5, {}))
        end)
    end)

    describe("ApplyCurve", function()
        it("should apply sqrt curve to positive values", function()
            assert.is_near(0.5, Math.ApplyCurve(0.25), 0.001)
            assert.is_near(0.707, Math.ApplyCurve(0.5), 0.001)
        end)

        it("should apply sqrt curve to negative values", function()
            assert.is_near(-0.5, Math.ApplyCurve(-0.25), 0.001)
        end)

        it("should preserve boundary values", function()
            assert.equals(0, Math.ApplyCurve(0))
            assert.equals(1, Math.ApplyCurve(1))
            assert.equals(-1, Math.ApplyCurve(-1))
        end)
    end)
end)
