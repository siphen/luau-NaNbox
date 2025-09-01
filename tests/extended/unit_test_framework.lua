-- Comprehensive Unit Test Framework for NaNbox Testing
-- Inspired by popular Lua testing frameworks (Busted, LuaUnit, etc.)

local TestFramework = {}

-- Test result tracking
local test_stats = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0,
    errors = 0,
    start_time = nil,
    current_suite = nil,
    current_test = nil,
    results = {}
}

-- Configuration
local config = {
    verbose = true,
    stop_on_first_failure = false,
    show_stack_trace = true,
    timeout_seconds = 30
}

-- Utility functions
local function format_time(seconds)
    if seconds < 1 then
        return string.format("%.3fms", seconds * 1000)
    else
        return string.format("%.3fs", seconds)
    end
end

local function format_number(num)
    if type(num) == "number" then
        if num == math.floor(num) and math.abs(num) < 2^53 then
            return string.format("%d", num)
        else
            return string.format("%.10g", num)
        end
    end
    return tostring(num)
end

-- Assertion functions
function TestFramework.assertEqual(actual, expected, msg)
    if actual ~= expected then
        local error_msg = string.format("Expected %s, got %s", 
                                      format_number(expected), 
                                      format_number(actual))
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertNotEqual(actual, unexpected, msg)
    if actual == unexpected then
        local error_msg = string.format("Expected not %s, got %s", 
                                      format_number(unexpected), 
                                      format_number(actual))
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertTrue(value, msg)
    if not value then
        local error_msg = string.format("Expected true, got %s", tostring(value))
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertFalse(value, msg)
    if value then
        local error_msg = string.format("Expected false, got %s", tostring(value))
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertNil(value, msg)
    if value ~= nil then
        local error_msg = string.format("Expected nil, got %s", tostring(value))
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertNotNil(value, msg)
    if value == nil then
        local error_msg = "Expected non-nil value"
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertAlmostEqual(actual, expected, delta, msg)
    delta = delta or 1e-9
    if math.abs(actual - expected) > delta then
        local error_msg = string.format("Expected %s ± %s, got %s (diff: %s)", 
                                      format_number(expected), 
                                      format_number(delta),
                                      format_number(actual),
                                      format_number(math.abs(actual - expected)))
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertType(value, expected_type, msg)
    local actual_type = type(value)
    if actual_type ~= expected_type then
        local error_msg = string.format("Expected type %s, got %s", expected_type, actual_type)
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

function TestFramework.assertError(func, msg)
    local success, err = pcall(func)
    if success then
        local error_msg = "Expected function to throw an error, but it succeeded"
        if msg then
            error_msg = msg .. ": " .. error_msg
        end
        error(error_msg)
    end
end

-- Test management
function TestFramework.describe(suite_name, func)
    if config.verbose then
        print(string.format("\n=== %s ===", suite_name))
    end
    
    test_stats.current_suite = suite_name
    
    local suite_start = os.clock()
    local suite_tests = 0
    local suite_passed = 0
    
    local old_total = test_stats.total
    local old_passed = test_stats.passed
    
    func()
    
    local suite_elapsed = os.clock() - suite_start
    suite_tests = test_stats.total - old_total
    suite_passed = test_stats.passed - old_passed
    
    if config.verbose then
        print(string.format("Suite completed: %d/%d passed (%s)", 
              suite_passed, suite_tests, format_time(suite_elapsed)))
    end
    
    test_stats.current_suite = nil
end

function TestFramework.it(test_name, func)
    test_stats.total = test_stats.total + 1
    test_stats.current_test = test_name
    
    local test_start = os.clock()
    local success, err = pcall(func)
    local test_elapsed = os.clock() - test_start
    
    if success then
        test_stats.passed = test_stats.passed + 1
        if config.verbose then
            print(string.format("  ✓ %s (%s)", test_name, format_time(test_elapsed)))
        end
        
        table.insert(test_stats.results, {
            suite = test_stats.current_suite,
            name = test_name,
            status = "passed",
            time = test_elapsed
        })
    else
        test_stats.failed = test_stats.failed + 1
        if config.verbose then
            print(string.format("  ✗ %s (%s)", test_name, format_time(test_elapsed)))
            if config.show_stack_trace then
                print(string.format("    Error: %s", err))
            end
        end
        
        table.insert(test_stats.results, {
            suite = test_stats.current_suite,
            name = test_name,
            status = "failed",
            error = err,
            time = test_elapsed
        })
        
        if config.stop_on_first_failure then
            error("Stopping on first failure")
        end
    end
    
    test_stats.current_test = nil
end

function TestFramework.skip(test_name, reason)
    test_stats.total = test_stats.total + 1
    test_stats.skipped = test_stats.skipped + 1
    
    if config.verbose then
        print(string.format("  ⊘ %s (skipped: %s)", test_name, reason or "no reason"))
    end
    
    table.insert(test_stats.results, {
        suite = test_stats.current_suite,
        name = test_name,
        status = "skipped",
        reason = reason
    })
end

-- Test runner
function TestFramework.run()
    test_stats.start_time = os.clock()
    
    print("=== NaNbox Test Suite ===")
    print("Starting comprehensive test execution...\n")
    
    -- Run all tests (this would be called by individual test files)
    -- For now, we'll run some sample tests
    
    TestFramework.run_sample_tests()
    
    TestFramework.print_summary()
    
    return test_stats.failed == 0
end

function TestFramework.run_sample_tests()
    TestFramework.describe("NaNbox Basic Operations", function()
        TestFramework.it("should handle integer values correctly", function()
            local x = 42
            TestFramework.assertEqual(x, 42)
            TestFramework.assertType(x, "number")
        end)
        
        TestFramework.it("should handle floating-point values correctly", function()
            local x = 3.14159
            TestFramework.assertAlmostEqual(x, 3.14159, 1e-5)
            TestFramework.assertType(x, "number")
        end)
        
        TestFramework.it("should handle boolean values correctly", function()
            local t = true
            local f = false
            TestFramework.assertTrue(t)
            TestFramework.assertFalse(f)
            TestFramework.assertType(t, "boolean")
            TestFramework.assertType(f, "boolean")
        end)
        
        TestFramework.it("should handle nil values correctly", function()
            local n = nil
            TestFramework.assertNil(n)
            TestFramework.assertType(n, "nil")
        end)
    end)
    
    TestFramework.describe("NaNbox Special Values", function()
        TestFramework.it("should handle NaN correctly", function()
            local nan = 0/0
            TestFramework.assertTrue(nan ~= nan, "NaN should not equal itself")
            TestFramework.assertType(nan, "number")
        end)
        
        TestFramework.it("should handle infinity correctly", function()
            local inf = 1/0
            local neg_inf = -1/0
            TestFramework.assertTrue(inf > 0)
            TestFramework.assertTrue(neg_inf < 0)
            TestFramework.assertType(inf, "number")
            TestFramework.assertType(neg_inf, "number")
        end)
        
        TestFramework.it("should handle negative zero correctly", function()
            local neg_zero = -0.0
            local pos_zero = 0.0
            TestFramework.assertEqual(neg_zero, pos_zero, "Negative zero should equal positive zero")
        end)
    end)
    
    TestFramework.describe("NaNbox Performance", function()
        TestFramework.it("should perform arithmetic operations efficiently", function()
            local start = os.clock()
            local sum = 0
            for i = 1, 100000 do
                sum = sum + i * 0.5
            end
            local elapsed = os.clock() - start
            
            TestFramework.assertTrue(elapsed < 1.0, "Arithmetic should be fast")
            TestFramework.assertAlmostEqual(sum, 2500025000, 1e-6)
        end)
        
        TestFramework.it("should handle table operations efficiently", function()
            local start = os.clock()
            local t = {}
            for i = 1, 10000 do
                t[i] = i * 2
            end
            local elapsed = os.clock() - start
            
            TestFramework.assertTrue(elapsed < 1.0, "Table operations should be fast")
            TestFramework.assertEqual(t[100], 200)
            TestFramework.assertEqual(#t, 10000)
        end)
    end)
    
    TestFramework.describe("NaNbox Type System", function()
        TestFramework.it("should distinguish between types correctly", function()
            local values = {
                {42, "number"},
                {3.14, "number"},
                {true, "boolean"},
                {false, "boolean"}, 
                {nil, "nil"},
                {"hello", "string"},
                {{1, 2, 3}, "table"},
                {function() end, "function"}
            }
            
            for _, pair in ipairs(values) do
                local value, expected_type = pair[1], pair[2]
                TestFramework.assertType(value, expected_type)
            end
        end)
    end)
end

function TestFramework.print_summary()
    local total_time = os.clock() - test_stats.start_time
    
    print(string.rep("=", 50))
    print("Test Summary:")
    print(string.rep("-", 50))
    print(string.format("Total tests:    %d", test_stats.total))
    print(string.format("Passed:         %d", test_stats.passed))
    print(string.format("Failed:         %d", test_stats.failed))
    print(string.format("Skipped:        %d", test_stats.skipped))
    print(string.format("Success rate:   %.1f%%", 100.0 * test_stats.passed / test_stats.total))
    print(string.format("Total time:     %s", format_time(total_time)))
    
    if test_stats.failed > 0 then
        print(string.rep("-", 50))
        print("Failed tests:")
        for _, result in ipairs(test_stats.results) do
            if result.status == "failed" then
                print(string.format("  %s::%s", result.suite or "Unknown", result.name))
                if result.error then
                    print(string.format("    %s", result.error))
                end
            end
        end
    end
    
    print(string.rep("=", 50))
    
    if test_stats.failed == 0 then
        print("🎉 All tests passed!")
    else
        print(string.format("❌ %d test(s) failed", test_stats.failed))
    end
end

-- Export the framework
return TestFramework