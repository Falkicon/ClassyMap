-- Time_spec.lua
-- Tests for Time domain

describe("Time", function()
    local Time

    before_each(function()
        Time = FenCore.Time
    end)

    describe("FormatDuration", function()
        it("should format seconds only", function()
            assert.equals("45 sec", Time.FormatDuration(45))
        end)

        it("should format minutes and seconds", function()
            assert.equals("2 min 30 sec", Time.FormatDuration(150))
        end)

        it("should format hours", function()
            local result = Time.FormatDuration(3661)
            assert.is_truthy(result:find("1 hour"))
            assert.is_truthy(result:find("1 min"))
        end)

        it("should format days", function()
            local result = Time.FormatDuration(86400 + 3600)
            assert.is_truthy(result:find("1 day"))
        end)

        it("should handle compact mode", function()
            local result = Time.FormatDuration(3661, { compact = true })
            assert.is_truthy(result:find("1h"))
            assert.is_truthy(result:find("1m"))
        end)

        it("should hide seconds when option set", function()
            local result = Time.FormatDuration(150, { showSeconds = false })
            assert.is_nil(result:find("sec"))
        end)

        it("should return 0s for zero", function()
            assert.equals("0s", Time.FormatDuration(0))
        end)

        it("should return 0s for negative", function()
            assert.equals("0s", Time.FormatDuration(-10))
        end)
    end)

    describe("FormatCooldown", function()
        it("should format seconds only", function()
            assert.equals("45", Time.FormatCooldown(45))
        end)

        it("should format MM:SS", function()
            assert.equals("2:30", Time.FormatCooldown(150))
        end)

        it("should format HH:MM:SS", function()
            assert.equals("1:01:01", Time.FormatCooldown(3661))
        end)

        it("should return 0 for zero", function()
            assert.equals("0", Time.FormatCooldown(0))
        end)

        it("should ceil seconds", function()
            assert.equals("3", Time.FormatCooldown(2.1))
        end)
    end)

    describe("FormatCooldownShort", function()
        it("should show decimals for small values", function()
            local result = Time.FormatCooldownShort(1.5)
            assert.is_truthy(result:find("1.5"))
        end)

        it("should show whole seconds for medium values", function()
            assert.equals("30", Time.FormatCooldownShort(29.5))
        end)

        it("should show minutes for 60+ seconds", function()
            assert.equals("2m", Time.FormatCooldownShort(90))
        end)

        it("should show hours for 3600+ seconds", function()
            assert.equals("2h", Time.FormatCooldownShort(7200))
        end)
    end)

    describe("ParseDuration", function()
        it("should parse seconds", function()
            local result = Time.ParseDuration("30s")
            assert.equals(30, result)
        end)

        it("should parse minutes", function()
            local result = Time.ParseDuration("5m")
            assert.equals(300, result)
        end)

        it("should parse hours", function()
            local result = Time.ParseDuration("2h")
            assert.equals(7200, result)
        end)

        it("should parse days", function()
            local result = Time.ParseDuration("1d")
            assert.equals(86400, result)
        end)

        it("should parse combined", function()
            local result = Time.ParseDuration("1h30m")
            assert.equals(5400, result)
        end)

        it("should parse with spaces", function()
            local result = Time.ParseDuration("1h 30m 15s")
            assert.equals(5415, result)
        end)

        it("should parse plain numbers as seconds", function()
            local result = Time.ParseDuration("90")
            assert.equals(90, result)
        end)

        it("should return nil for empty string", function()
            local result, err = Time.ParseDuration("")
            assert.is_nil(result)
            assert.is_truthy(err)
        end)

        it("should return nil for invalid format", function()
            local result, err = Time.ParseDuration("abc")
            assert.is_nil(result)
        end)
    end)

    describe("FormatRelative", function()
        it("should show just now for < 60 seconds", function()
            assert.equals("just now", Time.FormatRelative(30))
        end)

        it("should show minutes ago", function()
            local result = Time.FormatRelative(120)
            assert.is_truthy(result:find("2 min ago"))
        end)

        it("should show hours ago", function()
            local result = Time.FormatRelative(7200)
            assert.is_truthy(result:find("hour"))
        end)

        it("should show days ago", function()
            local result = Time.FormatRelative(172800)
            assert.is_truthy(result:find("2 days ago"))
        end)

        it("should show future for negative", function()
            local result = Time.FormatRelative(-120)
            assert.is_truthy(result:find("from now"))
        end)
    end)
end)
