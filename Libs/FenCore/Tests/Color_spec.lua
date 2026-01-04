-- Color_spec.lua
-- Tests for Color domain

describe("Color", function()
    local Color

    before_each(function()
        Color = FenCore.Color
    end)

    describe("Create", function()
        it("should create color with RGB values", function()
            local c = Color.Create(1, 0.5, 0)
            assert.equals(1, c.r)
            assert.equals(0.5, c.g)
            assert.equals(0, c.b)
            assert.equals(1, c.a)
        end)

        it("should create color with alpha", function()
            local c = Color.Create(1, 0.5, 0, 0.8)
            assert.equals(0.8, c.a)
        end)

        it("should clamp values to 0-1", function()
            local c = Color.Create(2, -0.5, 0.5)
            assert.equals(1, c.r)
            assert.equals(0, c.g)
        end)
    end)

    describe("Lerp", function()
        it("should interpolate between colors", function()
            local c1 = { r = 0, g = 0, b = 0 }
            local c2 = { r = 1, g = 1, b = 1 }
            local result = Color.Lerp(c1, c2, 0.5)

            assert.is_near(0.5, result.r, 0.001)
            assert.is_near(0.5, result.g, 0.001)
            assert.is_near(0.5, result.b, 0.001)
        end)

        it("should return first color at t=0", function()
            local c1 = { r = 1, g = 0, b = 0 }
            local c2 = { r = 0, g = 1, b = 0 }
            local result = Color.Lerp(c1, c2, 0)

            assert.equals(1, result.r)
            assert.equals(0, result.g)
        end)

        it("should return second color at t=1", function()
            local c1 = { r = 1, g = 0, b = 0 }
            local c2 = { r = 0, g = 1, b = 0 }
            local result = Color.Lerp(c1, c2, 1)

            assert.equals(0, result.r)
            assert.equals(1, result.g)
        end)

        it("should clamp t to 0-1", function()
            local c1 = { r = 0, g = 0, b = 0 }
            local c2 = { r = 1, g = 1, b = 1 }

            local result1 = Color.Lerp(c1, c2, -0.5)
            assert.equals(0, result1.r)

            local result2 = Color.Lerp(c1, c2, 1.5)
            assert.equals(1, result2.r)
        end)

        it("should interpolate alpha", function()
            local c1 = { r = 0, g = 0, b = 0, a = 0 }
            local c2 = { r = 1, g = 1, b = 1, a = 1 }
            local result = Color.Lerp(c1, c2, 0.5)

            assert.is_near(0.5, result.a, 0.001)
        end)
    end)

    describe("ForHealth", function()
        it("should return red at 0%", function()
            local c = Color.ForHealth(0)
            assert.equals(1, c.r)
            assert.equals(0, c.g)
        end)

        it("should return yellow at 50%", function()
            local c = Color.ForHealth(0.5)
            assert.equals(1, c.r)
            assert.equals(1, c.g)
        end)

        it("should return green at 100%", function()
            local c = Color.ForHealth(1)
            assert.equals(0, c.r)
            assert.equals(1, c.g)
        end)
    end)

    describe("ForProgress", function()
        it("should match ForHealth", function()
            local h = Color.ForHealth(0.5)
            local p = Color.ForProgress(0.5)
            assert.equals(h.r, p.r)
            assert.equals(h.g, p.g)
        end)
    end)

    describe("HexToRGB", function()
        it("should convert hex with #", function()
            local c = Color.HexToRGB("#FF0000")
            assert.equals(1, c.r)
            assert.equals(0, c.g)
            assert.equals(0, c.b)
        end)

        it("should convert hex without #", function()
            local c = Color.HexToRGB("00FF00")
            assert.equals(0, c.r)
            assert.equals(1, c.g)
            assert.equals(0, c.b)
        end)

        it("should handle 8-char hex with alpha", function()
            local c = Color.HexToRGB("FF000080")
            assert.is_near(0.5, c.a, 0.01)
        end)
    end)

    describe("RGBToHex", function()
        it("should convert to hex", function()
            local hex = Color.RGBToHex({ r = 1, g = 0, b = 0 })
            assert.equals("FF0000", hex)
        end)

        it("should include alpha when requested", function()
            local hex = Color.RGBToHex({ r = 1, g = 0, b = 0, a = 0.5 }, true)
            assert.equals("FF00007F", hex)
        end)
    end)

    describe("Darken", function()
        it("should darken color", function()
            local c = Color.Darken({ r = 1, g = 0.5, b = 0.25 }, 0.5)
            assert.is_near(0.5, c.r, 0.001)
            assert.is_near(0.25, c.g, 0.001)
            assert.is_near(0.125, c.b, 0.001)
        end)

        it("should return black at factor 0", function()
            local c = Color.Darken({ r = 1, g = 1, b = 1 }, 0)
            assert.equals(0, c.r)
            assert.equals(0, c.g)
            assert.equals(0, c.b)
        end)

        it("should preserve alpha", function()
            local c = Color.Darken({ r = 1, g = 1, b = 1, a = 0.5 }, 0.5)
            assert.equals(0.5, c.a)
        end)
    end)

    describe("Lighten", function()
        it("should lighten color", function()
            local c = Color.Lighten({ r = 0, g = 0, b = 0 }, 0.5)
            assert.is_near(0.5, c.r, 0.001)
            assert.is_near(0.5, c.g, 0.001)
            assert.is_near(0.5, c.b, 0.001)
        end)

        it("should return white at factor 1", function()
            local c = Color.Lighten({ r = 0, g = 0, b = 0 }, 1)
            assert.equals(1, c.r)
            assert.equals(1, c.g)
            assert.equals(1, c.b)
        end)
    end)
end)
