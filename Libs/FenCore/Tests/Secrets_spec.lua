-- Secrets_spec.lua
-- Tests for Secrets domain

describe("Secrets", function()
    local Secrets

    before_each(function()
        Secrets = FenCore.Secrets
    end)

    describe("IsSecret", function()
        it("should return false for nil", function()
            assert.is_false(Secrets.IsSecret(nil))
        end)

        it("should return false for regular numbers", function()
            assert.is_false(Secrets.IsSecret(42))
            assert.is_false(Secrets.IsSecret(0))
            assert.is_false(Secrets.IsSecret(-10))
        end)

        it("should return false for strings", function()
            assert.is_false(Secrets.IsSecret("hello"))
        end)

        it("should return false for tables", function()
            assert.is_false(Secrets.IsSecret({ x = 1 }))
        end)
    end)

    describe("SafeToString", function()
        it("should convert nil to 'nil'", function()
            assert.equals("nil", Secrets.SafeToString(nil))
        end)

        it("should convert numbers", function()
            assert.equals("42", Secrets.SafeToString(42))
        end)

        it("should convert strings", function()
            assert.equals("hello", Secrets.SafeToString("hello"))
        end)
    end)

    describe("SafeCompare", function()
        it("should return nil for nil operands", function()
            assert.is_nil(Secrets.SafeCompare(nil, 5, ">"))
            assert.is_nil(Secrets.SafeCompare(5, nil, ">"))
        end)

        it("should compare with >", function()
            assert.is_true(Secrets.SafeCompare(10, 5, ">"))
            assert.is_false(Secrets.SafeCompare(5, 10, ">"))
        end)

        it("should compare with <", function()
            assert.is_true(Secrets.SafeCompare(5, 10, "<"))
            assert.is_false(Secrets.SafeCompare(10, 5, "<"))
        end)

        it("should compare with >=", function()
            assert.is_true(Secrets.SafeCompare(10, 10, ">="))
            assert.is_true(Secrets.SafeCompare(10, 5, ">="))
        end)

        it("should compare with <=", function()
            assert.is_true(Secrets.SafeCompare(10, 10, "<="))
            assert.is_true(Secrets.SafeCompare(5, 10, "<="))
        end)

        it("should compare with ==", function()
            assert.is_true(Secrets.SafeCompare(10, 10, "=="))
            assert.is_false(Secrets.SafeCompare(10, 5, "=="))
        end)

        it("should compare with ~=", function()
            assert.is_true(Secrets.SafeCompare(10, 5, "~="))
            assert.is_false(Secrets.SafeCompare(10, 10, "~="))
        end)

        it("should return nil for invalid operator", function()
            assert.is_nil(Secrets.SafeCompare(10, 5, "invalid"))
        end)
    end)

    describe("SafeArithmetic", function()
        it("should perform operation on regular values", function()
            local result = Secrets.SafeArithmetic(10, function(v) return v * 2 end, 0)
            assert.equals(20, result)
        end)

        it("should return fallback for nil", function()
            local result = Secrets.SafeArithmetic(nil, function(v) return v * 2 end, -1)
            assert.equals(-1, result)
        end)

        it("should return fallback on operation error", function()
            local result = Secrets.SafeArithmetic(10, function(v) error("test error") end, 99)
            assert.equals(99, result)
        end)
    end)

    describe("CleanNumber", function()
        it("should return nil and false for nil", function()
            local num, isSecret = Secrets.CleanNumber(nil)
            assert.is_nil(num)
            assert.is_false(isSecret)
        end)

        it("should return number for regular numbers", function()
            local num, isSecret = Secrets.CleanNumber(42)
            assert.equals(42, num)
            assert.is_false(isSecret)
        end)

        it("should return nil and false for non-numbers", function()
            local num, isSecret = Secrets.CleanNumber("hello")
            assert.is_nil(num)
            assert.is_false(isSecret)
        end)
    end)

    describe("CountSecrets", function()
        it("should return 0 for nil", function()
            assert.equals(0, Secrets.CountSecrets(nil))
        end)

        it("should return 0 for empty table", function()
            assert.equals(0, Secrets.CountSecrets({}))
        end)

        it("should return 0 for table with no secrets", function()
            local tbl = { a = 1, b = 2, c = "hello" }
            assert.equals(0, Secrets.CountSecrets(tbl))
        end)

        it("should handle non-recursive by default", function()
            local tbl = { a = 1, nested = { b = 2 } }
            assert.equals(0, Secrets.CountSecrets(tbl))
        end)
    end)

    describe("HasSecrets", function()
        it("should return false for nil", function()
            assert.is_false(Secrets.HasSecrets(nil))
        end)

        it("should return false for empty table", function()
            assert.is_false(Secrets.HasSecrets({}))
        end)

        it("should return false for table with no secrets", function()
            local tbl = { a = 1, b = 2, c = "hello" }
            assert.is_false(Secrets.HasSecrets(tbl))
        end)
    end)
end)
