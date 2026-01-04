-- Text_spec.lua
-- Tests for Text domain

describe("Text", function()
    local Text

    before_each(function()
        Text = FenCore.Text
    end)

    describe("Truncate", function()
        it("should not truncate short strings", function()
            assert.equals("Hello", Text.Truncate("Hello", 10))
        end)

        it("should truncate long strings", function()
            assert.equals("Hello...", Text.Truncate("Hello World", 8))
        end)

        it("should use custom suffix", function()
            assert.equals("Hello~", Text.Truncate("Hello World", 6, "~"))
        end)

        it("should handle nil", function()
            assert.equals("", Text.Truncate(nil, 10))
        end)

        it("should handle very short maxLen", function()
            local result = Text.Truncate("Hello", 3)
            assert.equals(3, #result)
        end)
    end)

    describe("Pluralize", function()
        it("should use singular for 1", function()
            assert.equals("1 item", Text.Pluralize(1, "item"))
        end)

        it("should use plural for 0", function()
            assert.equals("0 items", Text.Pluralize(0, "item"))
        end)

        it("should use plural for > 1", function()
            assert.equals("5 items", Text.Pluralize(5, "item"))
        end)

        it("should use custom plural", function()
            assert.equals("2 children", Text.Pluralize(2, "child", "children"))
        end)
    end)

    describe("FormatNumber", function()
        it("should format with separators", function()
            assert.equals("1,234,567", Text.FormatNumber(1234567))
        end)

        it("should handle decimals", function()
            local result = Text.FormatNumber(1234.567, 2)
            assert.is_truthy(result:find("1,234"))
            assert.is_truthy(result:find("%.57"))
        end)

        it("should use custom separator", function()
            assert.equals("1.234.567", Text.FormatNumber(1234567, 0, "."))
        end)

        it("should handle small numbers", function()
            assert.equals("42", Text.FormatNumber(42))
        end)

        it("should handle negative numbers", function()
            assert.equals("-1,234", Text.FormatNumber(-1234))
        end)
    end)

    describe("FormatCompact", function()
        it("should format thousands", function()
            local result = Text.FormatCompact(1500)
            assert.is_truthy(result:find("K"))
        end)

        it("should format millions", function()
            local result = Text.FormatCompact(1500000)
            assert.is_truthy(result:find("M"))
        end)

        it("should format billions", function()
            local result = Text.FormatCompact(1500000000)
            assert.is_truthy(result:find("B"))
        end)

        it("should format trillions", function()
            local result = Text.FormatCompact(1500000000000)
            assert.is_truthy(result:find("T"))
        end)

        it("should not compact small numbers", function()
            assert.equals("500", Text.FormatCompact(500))
        end)
    end)

    describe("Capitalize", function()
        it("should capitalize first letter", function()
            assert.equals("Hello", Text.Capitalize("hello"))
        end)

        it("should lowercase rest", function()
            assert.equals("Hello", Text.Capitalize("HELLO"))
        end)

        it("should handle empty string", function()
            assert.equals("", Text.Capitalize(""))
        end)

        it("should handle nil", function()
            assert.equals("", Text.Capitalize(nil))
        end)
    end)

    describe("TitleCase", function()
        it("should capitalize each word", function()
            assert.equals("Hello World", Text.TitleCase("hello world"))
        end)

        it("should handle mixed case", function()
            assert.equals("Hello World", Text.TitleCase("hELLO wORLD"))
        end)
    end)

    describe("Pad", function()
        it("should pad left by default", function()
            assert.equals("  42", Text.Pad("42", 4))
        end)

        it("should pad right when specified", function()
            assert.equals("42  ", Text.Pad("42", 4, " ", true))
        end)

        it("should use custom character", function()
            assert.equals("0042", Text.Pad("42", 4, "0"))
        end)

        it("should not pad if already at length", function()
            assert.equals("hello", Text.Pad("hello", 5))
        end)

        it("should not truncate if longer", function()
            assert.equals("hello", Text.Pad("hello", 3))
        end)
    end)

    describe("StripColors", function()
        it("should remove color codes", function()
            local result = Text.StripColors("|cFFFF0000Red|r")
            assert.equals("Red", result)
        end)

        it("should remove multiple color codes", function()
            local result = Text.StripColors("|cFFFF0000Red|r and |cFF00FF00Green|r")
            assert.equals("Red and Green", result)
        end)

        it("should remove texture strings", function()
            local result = Text.StripColors("|TInterface\\Icons\\INV_Misc_QuestionMark:16|t Item")
            assert.equals(" Item", result)
        end)

        it("should handle nil", function()
            assert.equals("", Text.StripColors(nil))
        end)

        it("should handle strings without codes", function()
            assert.equals("Hello", Text.StripColors("Hello"))
        end)
    end)

    describe("FormatMemory", function()
        it("should format kilobytes", function()
            assert.equals("512 KB", Text.FormatMemory(512))
        end)

        it("should format megabytes", function()
            assert.equals("2.0 MB", Text.FormatMemory(2048))
        end)

        it("should format large megabytes", function()
            local result = Text.FormatMemory(5120)
            assert.is_truthy(result:find("MB"))
        end)

        it("should handle nil", function()
            assert.equals("0 KB", Text.FormatMemory(nil))
        end)

        it("should handle boundary value", function()
            assert.equals("1.0 MB", Text.FormatMemory(1024))
        end)
    end)

    describe("FormatBytes", function()
        it("should format bytes", function()
            assert.equals("512 B", Text.FormatBytes(512))
        end)

        it("should format kilobytes", function()
            local result = Text.FormatBytes(2048)
            assert.is_truthy(result:find("KB"))
        end)

        it("should format megabytes", function()
            local result = Text.FormatBytes(2 * 1024 * 1024)
            assert.is_truthy(result:find("MB"))
        end)

        it("should format gigabytes", function()
            local result = Text.FormatBytes(2 * 1024 * 1024 * 1024)
            assert.is_truthy(result:find("GB"))
        end)

        it("should handle nil", function()
            assert.equals("0 B", Text.FormatBytes(nil))
        end)
    end)
end)
