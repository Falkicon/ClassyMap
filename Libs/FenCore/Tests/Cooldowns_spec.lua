-- Cooldowns_spec.lua
-- Tests for Cooldowns domain

describe("Cooldowns", function()
    local Cooldowns, Result

    before_each(function()
        Cooldowns = FenCore.Cooldowns
        Result = FenCore.ActionResult
    end)

    describe("CalculateProgress", function()
        it("should calculate progress correctly", function()
            local result = Cooldowns.CalculateProgress(100, 10, 105)
            local data = Result.unwrap(result)

            assert.is_near(0.5, data.progress, 0.001)
            assert.is_near(5, data.remaining, 0.001)
            assert.is_true(data.isOnCooldown)
        end)

        it("should return complete when cooldown finished", function()
            local result = Cooldowns.CalculateProgress(100, 10, 115)
            local data = Result.unwrap(result)

            assert.equals(1, data.progress)
            assert.equals(0, data.remaining)
            assert.is_false(data.isOnCooldown)
        end)

        it("should handle no cooldown", function()
            local result = Cooldowns.CalculateProgress(0, 0, 100)
            local data = Result.unwrap(result)

            assert.equals(1, data.progress)
            assert.is_false(data.isOnCooldown)
        end)

        it("should error on nil input", function()
            local result = Cooldowns.CalculateProgress(nil, 10, 100)

            assert.is_false(Result.isSuccess(result))
        end)
    end)

    describe("Calculate", function()
        it("should calculate full state", function()
            local result = Cooldowns.Calculate({
                startTime = 100,
                duration = 10,
                now = 105,
            })
            local data = Result.unwrap(result)

            assert.is_near(0.5, data.progress, 0.001)
            assert.is_true(data.isOnCooldown)
            assert.is_true(data.isEnabled)
        end)

        it("should handle enabled flag", function()
            local result = Cooldowns.Calculate({
                startTime = 100,
                duration = 10,
                now = 105,
                enabled = false,
            })
            local data = Result.unwrap(result)

            assert.is_false(data.isEnabled)
        end)

        it("should default enabled to true", function()
            local result = Cooldowns.Calculate({
                startTime = 0,
                duration = 0,
                now = 100,
            })
            local data = Result.unwrap(result)

            assert.is_true(data.isEnabled)
        end)
    end)

    describe("AdvanceAnimation", function()
        it("should move toward target", function()
            local result = Cooldowns.AdvanceAnimation(0, 1, 0.1, 8)
            assert.is_true(result > 0)
            assert.is_true(result < 1)
        end)

        it("should use default animation speed", function()
            local result = Cooldowns.AdvanceAnimation(0, 1, 0.1)
            assert.is_true(result > 0)
        end)
    end)

    describe("HandleSecretFallback", function()
        it("should return usable true for true", function()
            local result = Cooldowns.HandleSecretFallback(true)
            local data = Result.unwrap(result)

            assert.is_true(data.usable)
            assert.is_false(data.isSecret)
        end)

        it("should return usable false for false", function()
            local result = Cooldowns.HandleSecretFallback(false)
            local data = Result.unwrap(result)

            assert.is_false(data.usable)
            assert.is_false(data.isSecret)
        end)
    end)

    describe("IsReady", function()
        it("should return true when ready", function()
            assert.is_true(Cooldowns.IsReady(100, 10, 115))
        end)

        it("should return false when on cooldown", function()
            assert.is_false(Cooldowns.IsReady(100, 10, 105))
        end)

        it("should return true when no cooldown", function()
            assert.is_true(Cooldowns.IsReady(0, 0, 100))
        end)
    end)

    describe("GetRemaining", function()
        it("should return remaining time", function()
            assert.equals(5, Cooldowns.GetRemaining(100, 10, 105))
        end)

        it("should return 0 when ready", function()
            assert.equals(0, Cooldowns.GetRemaining(100, 10, 115))
        end)

        it("should return 0 when no cooldown", function()
            assert.equals(0, Cooldowns.GetRemaining(0, 0, 100))
        end)
    end)
end)
