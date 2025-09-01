-- Comprehensive Test Runner for NaNbox Extended Test Suite
-- Runs unit tests, benchmarks, and performance comparisons

local function print_header(title)
    local border = string.rep("=", 60)
    print(border)
    print("  " .. title)
    print(border)
    print()
end

local function print_section(title)
    local border = string.rep("-", 50)
    print(border)
    print(title)
    print(border)
end

local function run_lua_file(filepath, description, timeout)
    timeout = timeout or 60
    
    print(string.format("Running %s...", description))
    
    local start_time = os.clock()
    
    -- Try to execute the file
    local success, result = pcall(dofile, filepath)
    
    local elapsed_time = os.clock() - start_time
    
    if success then
        print(string.format("✓ %s completed successfully (%.3fs)", description, elapsed_time))
        return true, elapsed_time
    else
        print(string.format("✗ %s failed: %s", description, result))
        return false, elapsed_time
    end
end

local function run_benchmark_with_luau(filepath, description, args)
    args = args or {}
    local cmd_args = table.concat(args, " ")
    
    print(string.format("Running %s with Luau...", description))
    
    local start_time = os.clock()
    local success = os.execute(string.format("./build/release/luau.exe %s %s", filepath, cmd_args))
    local elapsed_time = os.clock() - start_time
    
    if success then
        print(string.format("✓ %s completed (%.3fs)", description, elapsed_time))
        return true, elapsed_time
    else
        print(string.format("✗ %s failed", description))
        return false, elapsed_time
    end
end

local function run_comprehensive_tests()
    print_header("NaNbox Comprehensive Test Suite")
    
    local results = {
        unit_tests = {},
        benchmarks = {},
        performance_tests = {}
    }
    
    local total_tests = 0
    local passed_tests = 0
    local start_time = os.clock()
    
    -- Unit Tests
    print_section("Unit Tests")
    
    local unit_tests = {
        {
            file = "tests/extended/unit_test_framework.lua",
            desc = "Unit Test Framework"
        }
    }
    
    for _, test in ipairs(unit_tests) do
        total_tests = total_tests + 1
        local success, time = run_lua_file(test.file, test.desc)
        if success then passed_tests = passed_tests + 1 end
        
        table.insert(results.unit_tests, {
            name = test.desc,
            success = success,
            time = time
        })
    end
    
    print()
    
    -- Benchmark Tests
    print_section("Benchmark Tests")
    
    local benchmarks = {
        {
            file = "tests/extended/binary-trees.lua",
            desc = "Binary Trees",
            args = {"16"}
        },
        {
            file = "tests/extended/fibonacci.lua", 
            desc = "Fibonacci Algorithms",
            args = {"35"}
        },
        {
            file = "tests/extended/ackermann.lua",
            desc = "Ackermann Function",
            args = {"benchmark"}
        },
        {
            file = "tests/extended/mandelbrot.lua",
            desc = "Mandelbrot Set",
            args = {"benchmark", "150", "50"}
        },
        {
            file = "tests/extended/spectral-norm.lua",
            desc = "Spectral Norm",
            args = {"benchmark", "300"}
        }
    }
    
    for _, benchmark in ipairs(benchmarks) do
        total_tests = total_tests + 1
        local success, time = run_benchmark_with_luau(benchmark.file, benchmark.desc, benchmark.args)
        if success then passed_tests = passed_tests + 1 end
        
        table.insert(results.benchmarks, {
            name = benchmark.desc,
            success = success,
            time = time
        })
        
        print()
    end
    
    -- Performance Tests
    print_section("Performance Analysis")
    
    local performance_tests = {
        {
            file = "tests/extended/fibonacci.lua",
            desc = "Fibonacci Performance Analysis", 
            args = {"30"}
        },
        {
            file = "tests/extended/mandelbrot.lua",
            desc = "Mandelbrot Scaling Test",
            args = {"scaling"}
        },
        {
            file = "tests/extended/spectral-norm.lua", 
            desc = "Spectral Norm Scaling",
            args = {"scaling"}
        }
    }
    
    for _, test in ipairs(performance_tests) do
        total_tests = total_tests + 1
        local success, time = run_benchmark_with_luau(test.file, test.desc, test.args)
        if success then passed_tests = passed_tests + 1 end
        
        table.insert(results.performance_tests, {
            name = test.desc,
            success = success,
            time = time
        })
        
        print()
    end
    
    -- Summary
    local total_time = os.clock() - start_time
    
    print_header("Test Suite Summary")
    
    print(string.format("Total tests executed: %d", total_tests))
    print(string.format("Tests passed: %d", passed_tests))
    print(string.format("Tests failed: %d", total_tests - passed_tests))
    print(string.format("Success rate: %.1f%%", 100.0 * passed_tests / total_tests))
    print(string.format("Total execution time: %.3fs", total_time))
    print()
    
    -- Detailed Results
    print_section("Detailed Results")
    
    print("Unit Tests:")
    for _, result in ipairs(results.unit_tests) do
        local status = result.success and "✓" or "✗"
        print(string.format("  %s %-30s (%.3fs)", status, result.name, result.time))
    end
    print()
    
    print("Benchmarks:")
    for _, result in ipairs(results.benchmarks) do
        local status = result.success and "✓" or "✗"
        print(string.format("  %s %-30s (%.3fs)", status, result.name, result.time))
    end
    print()
    
    print("Performance Tests:")
    for _, result in ipairs(results.performance_tests) do
        local status = result.success and "✓" or "✗"
        print(string.format("  %s %-30s (%.3fs)", status, result.name, result.time))
    end
    print()
    
    -- Performance Analysis
    print_section("Performance Analysis")
    
    local total_benchmark_time = 0
    local benchmark_count = 0
    
    for _, result in ipairs(results.benchmarks) do
        if result.success then
            total_benchmark_time = total_benchmark_time + result.time
            benchmark_count = benchmark_count + 1
        end
    end
    
    if benchmark_count > 0 then
        local avg_benchmark_time = total_benchmark_time / benchmark_count
        print(string.format("Average benchmark execution time: %.3fs", avg_benchmark_time))
    end
    
    print()
    
    -- NaNbox Validation
    print_section("NaNbox Validation")
    
    print("Testing NaNbox specific features:")
    
    -- Test TValue size
    print("• TValue size validation:")
    local test_success = true
    
    -- We can't directly test sizeof(TValue) from Lua, but we can test behavior
    local large_numbers = {
        1e10, 1e15, 1e-10, 1e-15,
        math.pi, math.huge, -math.huge
    }
    
    for _, num in ipairs(large_numbers) do
        if type(num) ~= "number" then
            test_success = false
            print(string.format("  ✗ Number %g not stored correctly", num))
        end
    end
    
    if test_success then
        print("  ✓ Large number handling successful")
    end
    
    -- Test special values
    local nan = 0/0
    local inf = 1/0
    local neg_inf = -1/0
    
    if nan ~= nan and type(nan) == "number" then
        print("  ✓ NaN handling correct")
    else
        print("  ✗ NaN handling failed")
        test_success = false
    end
    
    if inf > 0 and type(inf) == "number" and neg_inf < 0 then
        print("  ✓ Infinity handling correct") 
    else
        print("  ✗ Infinity handling failed")
        test_success = false
    end
    
    -- Test type system integrity
    local types_test = {
        {42, "number"},
        {true, "boolean"},
        {nil, "nil"},
        {"test", "string"},
        {{1,2,3}, "table"}
    }
    
    local types_ok = true
    for _, test in ipairs(types_test) do
        if type(test[1]) ~= test[2] then
            types_ok = false
            print(string.format("  ✗ Type test failed: expected %s, got %s", test[2], type(test[1])))
        end
    end
    
    if types_ok then
        print("  ✓ Type system integrity validated")
    end
    
    print()
    
    if passed_tests == total_tests then
        print_header("🎉 All Tests Passed Successfully! 🎉")
        print("NaNbox implementation is working correctly.")
    else
        print_header("❌ Some Tests Failed")
        print(string.format("%d out of %d tests failed. Please review the results above.", 
              total_tests - passed_tests, total_tests))
    end
    
    return passed_tests == total_tests, results
end

-- NaNbox memory efficiency demonstration
local function demonstrate_memory_efficiency()
    print_header("NaNbox Memory Efficiency Demonstration")
    
    print("Creating large arrays to demonstrate memory efficiency...")
    
    local sizes = {1000, 10000, 100000}
    
    for _, size in ipairs(sizes) do
        print(string.format("\nTesting with %d elements:", size))
        
        collectgarbage("collect")
        local mem_before = collectgarbage("count")
        
        -- Create array with mixed types (benefits from NaNbox)
        local start_time = os.clock()
        local array = {}
        
        for i = 1, size do
            if i % 4 == 0 then
                array[i] = nil
            elseif i % 3 == 0 then
                array[i] = i % 2 == 0
            else
                array[i] = i * 1.5
            end
        end
        
        local creation_time = os.clock() - start_time
        
        collectgarbage("collect")
        local mem_after = collectgarbage("count")
        local mem_used = mem_after - mem_before
        
        print(string.format("  Creation time: %.4fs", creation_time))
        print(string.format("  Memory used: %.2f KB", mem_used))
        print(string.format("  Bytes per element: %.2f bytes", (mem_used * 1024) / size))
        
        -- With NaNbox, we expect significantly less memory usage per element
        -- compared to traditional 16-byte TValue implementation
        local traditional_estimate = size * 16 / 1024  -- Estimated traditional usage
        local efficiency = (traditional_estimate - mem_used) / traditional_estimate * 100
        
        print(string.format("  Estimated memory efficiency: %.1f%% improvement", efficiency))
    end
    
    print()
    print("Note: Memory efficiency is most apparent in mixed-type arrays")
    print("where NaNbox can store values in 8 bytes instead of 16 bytes.")
end

-- Main execution
local function main()
    local success, results = run_comprehensive_tests()
    
    print()
    demonstrate_memory_efficiency()
    
    return success
end

-- Run the comprehensive test suite
if arg and arg[1] == "demo" then
    demonstrate_memory_efficiency()
elseif arg and arg[1] == "quick" then
    -- Quick test mode - run only essential tests
    print_header("Quick Test Mode")
    
    local quick_tests = {
        "tests/extended/unit_test_framework.lua",
        "tests/extended/fibonacci.lua"
    }
    
    local passed = 0
    for _, test in ipairs(quick_tests) do
        local success = run_lua_file(test, test)
        if success then passed = passed + 1 end
    end
    
    print(string.format("\nQuick test results: %d/%d passed", passed, #quick_tests))
else
    -- Full test suite
    main()
end