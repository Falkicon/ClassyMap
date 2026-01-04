-- Tables_spec.lua
-- Tests for Tables domain

describe("Tables", function()
    local Tables

    before_each(function()
        Tables = FenCore.Tables
    end)

    describe("DeepCopy", function()
        it("should copy simple table", function()
            local original = { a = 1, b = 2 }
            local copy = Tables.DeepCopy(original)
            assert.equals(1, copy.a)
            assert.equals(2, copy.b)
            assert.not_equals(original, copy)
        end)

        it("should copy nested tables", function()
            local original = { a = { b = { c = 3 } } }
            local copy = Tables.DeepCopy(original)
            assert.equals(3, copy.a.b.c)
            original.a.b.c = 99
            assert.equals(3, copy.a.b.c) -- Should not be affected
        end)

        it("should copy non-table values", function()
            assert.equals(42, Tables.DeepCopy(42))
            assert.equals("hello", Tables.DeepCopy("hello"))
            assert.equals(true, Tables.DeepCopy(true))
        end)
    end)

    describe("Merge", function()
        it("should merge source into target", function()
            local target = { a = 1 }
            local source = { b = 2 }
            local result = Tables.Merge(target, source)
            assert.equals(1, result.a)
            assert.equals(2, result.b)
            assert.equals(target, result) -- Same table
        end)

        it("should overwrite existing keys", function()
            local target = { a = 1 }
            local source = { a = 2 }
            Tables.Merge(target, source)
            assert.equals(2, target.a)
        end)

        it("should handle nil source", function()
            local target = { a = 1 }
            local result = Tables.Merge(target, nil)
            assert.equals(1, result.a)
        end)
    end)

    describe("DeepMerge", function()
        it("should recursively merge nested tables", function()
            local target = { a = { b = 1 } }
            local source = { a = { c = 2 } }
            Tables.DeepMerge(target, source)
            assert.equals(1, target.a.b)
            assert.equals(2, target.a.c)
        end)
    end)

    describe("Keys", function()
        it("should return all keys", function()
            local tbl = { a = 1, b = 2, c = 3 }
            local keys = Tables.Keys(tbl)
            assert.equals(3, #keys)
        end)

        it("should return empty array for empty table", function()
            local keys = Tables.Keys({})
            assert.equals(0, #keys)
        end)

        it("should handle non-table input", function()
            local keys = Tables.Keys(nil)
            assert.equals(0, #keys)
        end)
    end)

    describe("Values", function()
        it("should return all values", function()
            local tbl = { a = 1, b = 2, c = 3 }
            local values = Tables.Values(tbl)
            assert.equals(3, #values)
        end)
    end)

    describe("Count", function()
        it("should count entries", function()
            local tbl = { a = 1, b = 2, c = 3 }
            assert.equals(3, Tables.Count(tbl))
        end)

        it("should return 0 for empty table", function()
            assert.equals(0, Tables.Count({}))
        end)

        it("should handle non-table", function()
            assert.equals(0, Tables.Count(nil))
        end)
    end)

    describe("IsEmpty", function()
        it("should return true for empty table", function()
            assert.is_true(Tables.IsEmpty({}))
        end)

        it("should return false for non-empty table", function()
            assert.is_false(Tables.IsEmpty({ a = 1 }))
        end)

        it("should return true for non-table", function()
            assert.is_true(Tables.IsEmpty(nil))
        end)
    end)

    describe("Contains", function()
        it("should find existing value", function()
            local tbl = { a = 1, b = 2, c = 3 }
            assert.is_true(Tables.Contains(tbl, 2))
        end)

        it("should not find missing value", function()
            local tbl = { a = 1, b = 2, c = 3 }
            assert.is_false(Tables.Contains(tbl, 99))
        end)
    end)

    describe("KeyOf", function()
        it("should find key for value", function()
            local tbl = { a = 1, b = 2, c = 3 }
            assert.equals("b", Tables.KeyOf(tbl, 2))
        end)

        it("should return nil for missing value", function()
            local tbl = { a = 1, b = 2 }
            assert.is_nil(Tables.KeyOf(tbl, 99))
        end)
    end)

    describe("Filter", function()
        it("should filter by predicate", function()
            local tbl = { a = 1, b = 2, c = 3, d = 4 }
            local result = Tables.Filter(tbl, function(v) return v > 2 end)
            assert.equals(2, Tables.Count(result))
            assert.equals(3, result.c)
            assert.equals(4, result.d)
        end)
    end)

    describe("Map", function()
        it("should transform values", function()
            local tbl = { a = 1, b = 2, c = 3 }
            local result = Tables.Map(tbl, function(v) return v * 2 end)
            assert.equals(2, result.a)
            assert.equals(4, result.b)
            assert.equals(6, result.c)
        end)
    end)
end)
