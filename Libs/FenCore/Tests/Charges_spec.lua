-- Charges_spec.lua
-- Tests for Charges domain

describe("Charges", function()
    local Charges, Result

    before_each(function()
        Charges = FenCore.Charges
        Result = FenCore.ActionResult
    end)

    describe("CalculateChargeFill", function()
        it("should return full for available charges", function()
            local result = Charges.CalculateChargeFill(1, 3, 0, 0, 100)
            local data = Result.unwrap(result)

            assert.equals(1, data.fill)
            assert.is_false(data.isRecharging)
        end)

        it("should return full for all available charges", function()
            local result = Charges.CalculateChargeFill(3, 3, 0, 0, 100)
            local data = Result.unwrap(result)

            assert.equals(1, data.fill)
        end)

        it("should calculate recharging progress", function()
            -- 3 current charges, charge 4 is recharging
            -- Started at t=100, duration=10, now=105 (50% done)
            local result = Charges.CalculateChargeFill(4, 3, 100, 10, 105)
            local data = Result.unwrap(result)

            assert.is_near(0.5, data.fill, 0.001)
            assert.is_true(data.isRecharging)
        end)

        it("should return empty for future charges", function()
            local result = Charges.CalculateChargeFill(5, 3, 100, 10, 105)
            local data = Result.unwrap(result)

            assert.equals(0, data.fill)
            assert.is_false(data.isRecharging)
        end)

        it("should error on nil input", function()
            local result = Charges.CalculateChargeFill(nil, 3, 0, 0, 100)

            assert.is_false(Result.isSuccess(result))
        end)
    end)

    describe("CalculateAll", function()
        it("should calculate all charge states", function()
            local result = Charges.CalculateAll({
                currentCharges = 2,
                maxCharges = 4,
                chargeStart = 100,
                chargeDuration = 10,
                now = 105,
            })
            local data = Result.unwrap(result)

            assert.equals(4, #data.charges)
            assert.equals(1, data.charges[1].fill)
            assert.equals(1, data.charges[2].fill)
            assert.is_near(0.5, data.charges[3].fill, 0.001)
            assert.equals(0, data.charges[4].fill)
            assert.is_false(data.allFull)
            assert.is_true(data.anyRecharging)
        end)

        it("should detect all full", function()
            local result = Charges.CalculateAll({
                currentCharges = 4,
                maxCharges = 4,
                chargeStart = 0,
                chargeDuration = 0,
                now = 100,
            })
            local data = Result.unwrap(result)

            assert.is_true(data.allFull)
            assert.is_false(data.anyRecharging)
        end)

        it("should handle empty charges", function()
            local result = Charges.CalculateAll({
                currentCharges = 0,
                maxCharges = 3,
                chargeStart = 100,
                chargeDuration = 10,
                now = 105,
            })
            local data = Result.unwrap(result)

            assert.is_near(0.5, data.charges[1].fill, 0.001)
            assert.equals(0, data.charges[2].fill)
        end)
    end)

    describe("AdvanceAnimation", function()
        it("should move toward target", function()
            local result = Charges.AdvanceAnimation(0, 1, 0.1, 8)
            assert.is_true(result > 0)
            assert.is_true(result < 1)
        end)

        it("should converge on target over time", function()
            local value = 0
            for i = 1, 100 do
                value = Charges.AdvanceAnimation(value, 1, 0.016, 8)
            end
            assert.is_near(1, value, 0.01)
        end)

        it("should use default animation speed", function()
            local result = Charges.AdvanceAnimation(0, 1, 0.1)
            assert.is_true(result > 0)
        end)
    end)

    describe("HandleSecretFallback", function()
        it("should return max charges when usable", function()
            local result = Charges.HandleSecretFallback(true, 6)
            local data = Result.unwrap(result)

            assert.equals(6, data.currentCharges)
            assert.is_false(data.isSecret)
        end)

        it("should return 0 when not usable", function()
            local result = Charges.HandleSecretFallback(false, 6)
            local data = Result.unwrap(result)

            assert.equals(0, data.currentCharges)
            assert.is_false(data.isSecret)
        end)
    end)
end)
