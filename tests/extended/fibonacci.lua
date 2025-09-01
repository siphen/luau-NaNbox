-- Fibonacci benchmark - multiple implementations for NaNbox testing

-- Recursive implementation (classical)
local function fibonacci_recursive(n)
    if n < 2 then
        return n
    else
        return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)
    end
end

-- Iterative implementation (optimized)
local function fibonacci_iterative(n)
    if n < 2 then return n end
    
    local a, b = 0, 1
    for i = 2, n do
        a, b = b, a + b
    end
    return b
end

-- Memoized implementation (cache-friendly)
local function fibonacci_memoized(n, memo)
    memo = memo or {}
    
    if memo[n] then
        return memo[n]
    end
    
    if n < 2 then
        memo[n] = n
        return n
    end
    
    memo[n] = fibonacci_memoized(n - 1, memo) + fibonacci_memoized(n - 2, memo)
    return memo[n]
end

-- Matrix-based implementation (mathematical)
local function matrix_multiply(a, b)
    return {
        a[1]*b[1] + a[2]*b[3], a[1]*b[2] + a[2]*b[4],
        a[3]*b[1] + a[4]*b[3], a[3]*b[2] + a[4]*b[4]
    }
end

local function matrix_power(matrix, n)
    if n == 1 then return matrix end
    if n % 2 == 0 then
        local half = matrix_power(matrix, n / 2)
        return matrix_multiply(half, half)
    else
        return matrix_multiply(matrix, matrix_power(matrix, n - 1))
    end
end

local function fibonacci_matrix(n)
    if n < 2 then return n end
    local fib_matrix = {1, 1, 1, 0}
    local result = matrix_power(fib_matrix, n)
    return result[2]
end

-- Benchmark runner
local function benchmark_fibonacci(impl_name, func, n, iterations)
    iterations = iterations or 1
    
    local start = os.clock()
    local result
    for i = 1, iterations do
        result = func(n)
    end
    local elapsed = os.clock() - start
    
    return result, elapsed, elapsed / iterations
end

-- Main benchmark function
local function run_fibonacci_benchmarks(n)
    n = n or 40
    local iterations = n > 35 and 1 or 5
    
    print("=== Fibonacci Benchmark Suite ===")
    print(string.format("Computing fibonacci(%d) with %d iterations each", n, iterations))
    print()
    
    local implementations = {
        {"Recursive", fibonacci_recursive},
        {"Iterative", fibonacci_iterative}, 
        {"Memoized", fibonacci_memoized},
        {"Matrix", fibonacci_matrix}
    }
    
    local results = {}
    
    for _, impl in ipairs(implementations) do
        local name, func = impl[1], impl[2]
        local result, total_time, avg_time = benchmark_fibonacci(name, func, n, iterations)
        
        table.insert(results, {
            name = name,
            result = result,
            total_time = total_time,
            avg_time = avg_time,
            iterations = iterations
        })
        
        print(string.format("%-12s: result=%d, total=%.4fs, avg=%.4fs", 
              name, result, total_time, avg_time))
    end
    
    print()
    
    -- Verify all implementations give the same result
    local expected = results[1].result
    local all_correct = true
    for _, result in ipairs(results) do
        if result.result ~= expected then
            all_correct = false
            print(string.format("ERROR: %s returned %d, expected %d", 
                  result.name, result.result, expected))
        end
    end
    
    if all_correct then
        print("✓ All implementations returned correct result:", expected)
    end
    
    return results
end

-- Stress test for NaNbox number handling
local function fibonacci_stress_test()
    print("=== Fibonacci NaNbox Stress Test ===")
    
    local test_values = {5, 10, 20, 30, 40, 45}
    
    for _, n in ipairs(test_values) do
        local result = fibonacci_iterative(n)
        print(string.format("fib(%2d) = %12d (%.2e)", n, result, result))
        
        -- Test large number handling
        if result > 2^53 then
            print("  ⚠ Result exceeds double precision integer range")
        end
    end
    
    -- Test edge cases
    local edge_cases = {0, 1, 2}
    print("\nEdge cases:")
    for _, n in ipairs(edge_cases) do
        local result = fibonacci_iterative(n)
        print(string.format("fib(%d) = %d", n, result))
    end
end

-- Run benchmarks if executed directly
if arg and arg[1] then
    local n = tonumber(arg[1])
    if n and n > 0 then
        run_fibonacci_benchmarks(n)
        print()
        fibonacci_stress_test()
    else
        print("Usage: luau fibonacci.lua <number>")
    end
else
    run_fibonacci_benchmarks(35)
    print()
    fibonacci_stress_test()
end