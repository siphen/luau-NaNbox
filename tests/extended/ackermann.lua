-- Ackermann function benchmark - Classic recursive function for NaNbox testing

-- Standard Ackermann function implementation
local function ackermann(m, n)
    if m == 0 then
        return n + 1
    elseif n == 0 then
        return ackermann(m - 1, 1)
    else
        return ackermann(m - 1, ackermann(m, n - 1))
    end
end

-- Optimized Ackermann with memoization
local function ackermann_memo(m, n, cache)
    cache = cache or {}
    
    local key = m * 1000 + n  -- Simple key encoding
    if cache[key] then
        return cache[key]
    end
    
    local result
    if m == 0 then
        result = n + 1
    elseif n == 0 then
        result = ackermann_memo(m - 1, 1, cache)
    else
        result = ackermann_memo(m - 1, ackermann_memo(m, n - 1, cache), cache)
    end
    
    cache[key] = result
    return result
end

-- Iterative implementation for comparison (limited cases)
local function ackermann_iterative(m, n)
    if m == 0 then return n + 1 end
    if m == 1 then return n + 2 end
    if m == 2 then return 2 * n + 3 end
    if m == 3 then return 2^(n + 3) - 3 end
    
    -- Fall back to recursive for m >= 4
    return ackermann(m, n)
end

-- Benchmark single Ackermann call
local function benchmark_ackermann_call(impl_name, func, m, n)
    print(string.format("Computing %s(%d, %d)...", impl_name, m, n))
    
    local start = os.clock()
    local result = func(m, n)
    local elapsed = os.clock() - start
    
    print(string.format("%-15s: ack(%d,%d) = %d (%.4fs)", impl_name, m, n, result, elapsed))
    return result, elapsed
end

-- Comprehensive Ackermann benchmark suite
local function run_ackermann_benchmarks()
    print("=== Ackermann Function Benchmark Suite ===")
    print("Testing recursive function performance with NaNbox")
    print()
    
    -- Test cases: (m, n) pairs with increasing complexity
    local test_cases = {
        {0, 0}, {0, 5}, {0, 10},
        {1, 0}, {1, 5}, {1, 10},
        {2, 0}, {2, 5}, {2, 10},
        {3, 0}, {3, 5}, {3, 8},
        {4, 0}, {4, 1}  -- Very expensive beyond this
    }
    
    local implementations = {
        {"Standard", ackermann},
        {"Memoized", ackermann_memo},
        {"Iterative", ackermann_iterative}
    }
    
    local results = {}
    
    for _, test_case in ipairs(test_cases) do
        local m, n = test_case[1], test_case[2]
        print(string.format("--- Test case: m=%d, n=%d ---", m, n))
        
        local test_results = {}
        
        for _, impl in ipairs(implementations) do
            local name, func = impl[1], impl[2]
            
            -- Skip expensive computations for basic implementation
            if name == "Standard" and (m >= 4 and n >= 2) then
                print(string.format("%-15s: skipped (too expensive)", name))
            else
                local result, time = benchmark_ackermann_call(name, func, m, n)
                test_results[name] = {result = result, time = time}
            end
        end
        
        -- Verify results match (where computed)
        local expected = nil
        for name, res in pairs(test_results) do
            if expected == nil then
                expected = res.result
            elseif expected ~= res.result then
                print(string.format("ERROR: %s returned %d, expected %d", name, res.result, expected))
            end
        end
        
        table.insert(results, {m = m, n = n, implementations = test_results})
        print()
    end
    
    return results
end

-- NaNbox stress test with large Ackermann values
local function ackermann_stress_test()
    print("=== Ackermann NaNbox Stress Test ===")
    print("Testing large number handling and edge cases")
    print()
    
    -- Test cases that produce large numbers
    local large_cases = {
        {0, 100},   -- n + 1 = 101
        {1, 100},   -- n + 2 = 102  
        {2, 20},    -- 2n + 3 = 43
        {3, 10},    -- 2^(n+3) - 3 = 8189
        {3, 12}     -- 2^(n+3) - 3 = 32765
    }
    
    print("Large value cases:")
    for _, case in ipairs(large_cases) do
        local m, n = case[1], case[2]
        local result = ackermann_iterative(m, n)
        print(string.format("ack(%d,%2d) = %8d (%.2e)", m, n, result, result))
        
        -- Check if result fits in double precision integer range
        if result > 2^53 then
            print("  ⚠ Result exceeds double precision integer range")
        end
    end
    
    print()
    
    -- Edge case testing
    print("Edge cases:")
    local edge_cases = {
        {0, 0}, -- Minimum case
        {1, 0}, -- Base cases
        {2, 0},
        {3, 0},
        {4, 0}  -- Most expensive base case
    }
    
    for _, case in ipairs(edge_cases) do
        local m, n = case[1], case[2]
        local result = ackermann(m, n)
        print(string.format("ack(%d,%d) = %d", m, n, result))
    end
end

-- Performance comparison
local function ackermann_performance_comparison()
    print("=== Ackermann Performance Comparison ===")
    print("Comparing recursive vs memoized vs iterative")
    print()
    
    local comparison_cases = {
        {2, 8},
        {3, 6}, 
        {3, 8}
    }
    
    for _, case in ipairs(comparison_cases) do
        local m, n = case[1], case[2]
        print(string.format("Performance for ack(%d, %d):", m, n))
        
        -- Standard recursive
        local start = os.clock()
        local result1 = ackermann(m, n)
        local time1 = os.clock() - start
        
        -- Memoized
        start = os.clock()
        local result2 = ackermann_memo(m, n)
        local time2 = os.clock() - start
        
        -- Iterative  
        start = os.clock()
        local result3 = ackermann_iterative(m, n)
        local time3 = os.clock() - start
        
        print(string.format("  Recursive:  %.4fs (result: %d)", time1, result1))
        print(string.format("  Memoized:   %.4fs (result: %d)", time2, result2))  
        print(string.format("  Iterative:  %.4fs (result: %d)", time3, result3))
        
        if time1 > 0 and time2 > 0 then
            print(string.format("  Speedup:    %.1fx (memoized vs recursive)", time1/time2))
        end
        print()
    end
end

-- Main execution
if arg and arg[1] then
    local mode = arg[1]
    if mode == "benchmark" then
        run_ackermann_benchmarks()
    elseif mode == "stress" then
        ackermann_stress_test()
    elseif mode == "compare" then
        ackermann_performance_comparison()
    else
        print("Usage: luau ackermann.lua [benchmark|stress|compare]")
    end
else
    run_ackermann_benchmarks()
    print()
    ackermann_stress_test()
    print()
    ackermann_performance_comparison()
end