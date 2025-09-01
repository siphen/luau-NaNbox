-- Spectral Norm benchmark from Computer Language Benchmarks Game
-- Matrix operations and eigenvalue computation for NaNbox testing

-- Calculate A(i,j) matrix element
local function A(i, j)
    return 1.0 / ((i + j) * (i + j + 1) / 2 + i + 1)
end

-- Multiply matrix A times vector u
local function multiplyAu(n, u, v)
    for i = 1, n do
        local sum = 0.0
        for j = 1, n do
            sum = sum + A(i - 1, j - 1) * u[j]
        end
        v[i] = sum
    end
end

-- Multiply matrix A transpose times vector u  
local function multiplyAtu(n, u, v)
    for i = 1, n do
        local sum = 0.0
        for j = 1, n do
            sum = sum + A(j - 1, i - 1) * u[j]
        end
        v[i] = sum
    end
end

-- Multiply matrix A transpose times A times vector u
local function multiplyAtAu(n, u, v, w)
    multiplyAu(n, u, w)
    multiplyAtu(n, w, v)
end

-- Calculate spectral norm of matrix A
local function spectral_norm(n)
    -- Initialize vectors
    local u = {}
    local v = {}
    local w = {}
    
    for i = 1, n do
        u[i] = 1.0
        v[i] = 0.0
        w[i] = 0.0
    end
    
    -- Power method iterations
    for iter = 1, 10 do
        multiplyAtAu(n, u, v, w)
        multiplyAtAu(n, v, u, w)
    end
    
    -- Calculate eigenvalue approximation
    local vBv = 0.0
    local vv = 0.0
    
    for i = 1, n do
        vBv = vBv + u[i] * v[i]
        vv = vv + v[i] * v[i]
    end
    
    return math.sqrt(vBv / vv)
end

-- Benchmark spectral norm computation
local function benchmark_spectral_norm(n, iterations)
    n = n or 500
    iterations = iterations or 3
    
    print("=== Spectral Norm Benchmark ===")
    print(string.format("Matrix size: %dx%d, Iterations: %d", n, n, iterations))
    print()
    
    local results = {}
    local times = {}
    
    for run = 1, iterations do
        print(string.format("Run %d:", run))
        
        local start = os.clock()
        local result = spectral_norm(n)
        local elapsed = os.clock() - start
        
        print(string.format("  Spectral norm: %.9f", result))
        print(string.format("  Time: %.4fs", elapsed))
        print()
        
        table.insert(results, result)
        table.insert(times, elapsed)
    end
    
    -- Calculate statistics
    local sum_result = 0.0
    local sum_time = 0.0
    local min_time, max_time = math.huge, 0
    
    for i = 1, iterations do
        sum_result = sum_result + results[i]
        sum_time = sum_time + times[i]
        min_time = math.min(min_time, times[i])
        max_time = math.max(max_time, times[i])
    end
    
    local avg_result = sum_result / iterations
    local avg_time = sum_time / iterations
    
    print("Summary:")
    print(string.format("  Average result: %.9f", avg_result))
    print(string.format("  Average time:   %.4fs", avg_time))
    print(string.format("  Min time:       %.4fs", min_time))
    print(string.format("  Max time:       %.4fs", max_time))
    print(string.format("  Time variation: %.2f%%", 100.0 * (max_time - min_time) / avg_time))
    
    return results, times
end

-- Performance scaling test
local function spectral_norm_scaling_test()
    print("=== Spectral Norm Scaling Test ===")
    print("Testing performance scaling with different matrix sizes")
    print()
    
    local sizes = {100, 200, 300, 500}
    
    print("Size\tTime(s)\tResult\t\tOps/sec")
    print("-" .. string.rep("-", 40))
    
    for _, n in ipairs(sizes) do
        local start = os.clock()
        local result = spectral_norm(n)
        local elapsed = os.clock() - start
        
        -- Estimate operations: roughly 10 * 2 * n^2 operations
        local ops = 20 * n * n
        local ops_per_sec = ops / elapsed
        
        print(string.format("%d\t%.3f\t%.9f\t%.0f", n, elapsed, result, ops_per_sec))
    end
    
    print()
end

-- Precision test for different matrix sizes
local function spectral_norm_precision_test()
    print("=== Spectral Norm Precision Test ===")
    print("Testing numerical precision with different matrix sizes")
    print()
    
    local sizes = {50, 100, 200, 500, 1000}
    
    print("Size\tSpectral Norm\t\tExpected Range")
    print("-" .. string.rep("-", 50))
    
    for _, n in ipairs(sizes) do
        local result = spectral_norm(n)
        
        -- For the spectral norm benchmark, results should be close to 1.274
        local expected_min, expected_max = 1.270, 1.280
        local status = (result >= expected_min and result <= expected_max) and "OK" or "CHECK"
        
        print(string.format("%d\t%.9f\t\t[%.3f, %.3f] %s", 
              n, result, expected_min, expected_max, status))
        
        if n > 500 then
            print("  (Computation may take longer for large matrices)")
        end
    end
    
    print()
end

-- Matrix element access pattern test
local function matrix_access_test()
    print("=== Matrix Access Pattern Test ===")
    print("Testing different matrix access patterns")
    print()
    
    local n = 200
    local u = {}
    local v = {}
    local w = {}
    
    -- Initialize vectors
    for i = 1, n do
        u[i] = 1.0
        v[i] = 0.0
        w[i] = 0.0
    end
    
    -- Test matrix multiplication performance
    local operations = {
        {"A * u", function() multiplyAu(n, u, v) end},
        {"A^T * u", function() multiplyAtu(n, u, v) end}, 
        {"A^T * A * u", function() multiplyAtAu(n, u, v, w) end}
    }
    
    for _, op in ipairs(operations) do
        local name, func = op[1], op[2]
        
        local start = os.clock()
        for i = 1, 10 do
            func()
        end
        local elapsed = os.clock() - start
        
        print(string.format("%-12s: %.4fs (10 iterations)", name, elapsed))
    end
    
    print()
end

-- NaNbox floating-point test
local function floating_point_test()
    print("=== Floating Point Precision Test ===")
    print("Testing floating-point operations with NaNbox")
    print()
    
    -- Test matrix element computation
    print("Matrix element A(i,j) values:")
    local positions = {
        {0, 0}, {0, 1}, {1, 0}, {1, 1},
        {10, 10}, {50, 50}, {100, 100}
    }
    
    for _, pos in ipairs(positions) do
        local i, j = pos[1], pos[2]
        local value = A(i, j)
        print(string.format("A(%2d,%2d) = %.10f", i, j, value))
    end
    
    print()
    
    -- Test vector operations
    print("Vector operations test:")
    local test_size = 10
    local u = {}
    local v = {}
    
    for i = 1, test_size do
        u[i] = i * 0.1
        v[i] = 0.0
    end
    
    multiplyAu(test_size, u, v)
    
    print("Input vector u:")
    for i = 1, test_size do
        print(string.format("u[%2d] = %.3f", i, u[i]))
    end
    
    print("\nOutput vector v = A * u:")
    for i = 1, test_size do
        print(string.format("v[%2d] = %.6f", i, v[i]))
    end
    
    print()
end

-- Main execution
if arg and arg[1] then
    local mode = arg[1]
    local n = arg[2] and tonumber(arg[2]) or 500
    
    if mode == "benchmark" then
        benchmark_spectral_norm(n)
    elseif mode == "scaling" then
        spectral_norm_scaling_test()
    elseif mode == "precision" then
        spectral_norm_precision_test()
    elseif mode == "access" then
        matrix_access_test()
    elseif mode == "float" then
        floating_point_test()
    else
        print("Usage: luau spectral-norm.lua [benchmark|scaling|precision|access|float] [size]")
    end
else
    benchmark_spectral_norm(300, 3)
    print()
    spectral_norm_scaling_test()
    print()
    spectral_norm_precision_test()
    print()
    matrix_access_test()
    print()
    floating_point_test()
end