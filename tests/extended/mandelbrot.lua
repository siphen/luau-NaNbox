-- Mandelbrot Set benchmark - Complex number computation for NaNbox testing

-- Mandelbrot iteration function
local function mandelbrot_point(cx, cy, max_iter)
    local zx, zy = 0.0, 0.0
    local zx2, zy2 = 0.0, 0.0
    
    for i = 0, max_iter - 1 do
        if zx2 + zy2 > 4.0 then
            return i
        end
        
        zy = 2.0 * zx * zy + cy
        zx = zx2 - zy2 + cx
        zx2 = zx * zx
        zy2 = zy * zy
    end
    
    return max_iter
end

-- Generate Mandelbrot set with given parameters
local function generate_mandelbrot(size, max_iter)
    size = size or 200
    max_iter = max_iter or 50
    
    local result = {}
    local scale = 3.0 / size
    
    for y = 0, size - 1 do
        local row = {}
        local cy = y * scale - 1.5
        
        for x = 0, size - 1 do
            local cx = x * scale - 2.0
            local iterations = mandelbrot_point(cx, cy, max_iter)
            table.insert(row, iterations)
        end
        
        table.insert(result, row)
    end
    
    return result
end

-- Count points in the set (iterations == max_iter)
local function count_mandelbrot_points(mandelbrot_data, max_iter)
    local count = 0
    local total = 0
    
    for _, row in ipairs(mandelbrot_data) do
        for _, iterations in ipairs(row) do
            if iterations == max_iter then
                count = count + 1
            end
            total = total + 1
        end
    end
    
    return count, total
end

-- Benchmark Mandelbrot generation
local function benchmark_mandelbrot(size, max_iter, runs)
    size = size or 200
    max_iter = max_iter or 50
    runs = runs or 3
    
    print("=== Mandelbrot Set Benchmark ===")
    print(string.format("Size: %dx%d, Max iterations: %d, Runs: %d", size, size, max_iter, runs))
    print()
    
    local times = {}
    local results = {}
    
    for run = 1, runs do
        print(string.format("Run %d:", run))
        
        local start = os.clock()
        local mandelbrot_data = generate_mandelbrot(size, max_iter)
        local gen_time = os.clock() - start
        
        start = os.clock()
        local in_set, total = count_mandelbrot_points(mandelbrot_data, max_iter)
        local count_time = os.clock() - start
        
        local total_time = gen_time + count_time
        
        print(string.format("  Generation: %.4fs", gen_time))
        print(string.format("  Counting:   %.4fs", count_time))
        print(string.format("  Total:      %.4fs", total_time))
        print(string.format("  In set:     %d/%d (%.2f%%)", in_set, total, 100.0 * in_set / total))
        
        table.insert(times, total_time)
        table.insert(results, {in_set = in_set, total = total})
        print()
    end
    
    -- Calculate statistics
    local sum = 0
    local min_time, max_time = math.huge, 0
    
    for _, time in ipairs(times) do
        sum = sum + time
        min_time = math.min(min_time, time)
        max_time = math.max(max_time, time)
    end
    
    local avg_time = sum / runs
    
    print("Summary:")
    print(string.format("  Average time: %.4fs", avg_time))
    print(string.format("  Min time:     %.4fs", min_time))
    print(string.format("  Max time:     %.4fs", max_time))
    print(string.format("  Variation:    %.2f%%", 100.0 * (max_time - min_time) / avg_time))
    
    return results, times
end

-- Performance scaling test
local function mandelbrot_scaling_test()
    print("=== Mandelbrot Scaling Test ===")
    print("Testing performance scaling with different sizes")
    print()
    
    local sizes = {50, 100, 200, 300}
    local max_iter = 50
    
    print("Size\tTime(s)\tPoints/sec\tIn Set")
    print("-" .. string.rep("-", 35))
    
    for _, size in ipairs(sizes) do
        local start = os.clock()
        local mandelbrot_data = generate_mandelbrot(size, max_iter)
        local elapsed = os.clock() - start
        
        local in_set, total = count_mandelbrot_points(mandelbrot_data, max_iter)
        local points_per_sec = total / elapsed
        
        print(string.format("%d\t%.3f\t%.0f\t\t%d/%d", 
              size, elapsed, points_per_sec, in_set, total))
    end
    
    print()
end

-- Complex number precision test for NaNbox
local function mandelbrot_precision_test()
    print("=== Mandelbrot Precision Test ===")
    print("Testing floating-point precision with NaNbox")
    print()
    
    -- Test specific points with known behavior
    local test_points = {
        {cx = -2.0, cy = 0.0, expected = "escapes quickly"},
        {cx = -1.0, cy = 0.0, expected = "escapes"},
        {cx = 0.0, cy = 0.0, expected = "in set"},
        {cx = -0.75, cy = 0.0, expected = "in set"},
        {cx = 0.25, cy = 0.0, expected = "escapes"},
        {cx = -0.5, cy = 0.5, expected = "escapes"},
        {cx = -0.1, cy = 0.8, expected = "escapes"}
    }
    
    local max_iter = 1000
    
    for _, point in ipairs(test_points) do
        local iterations = mandelbrot_point(point.cx, point.cy, max_iter)
        local status = iterations == max_iter and "in set" or string.format("escapes in %d", iterations)
        
        print(string.format("Point (%.2f, %.2f): %s [%s]", 
              point.cx, point.cy, status, point.expected))
    end
    
    print()
    
    -- Test extreme coordinates
    print("Extreme coordinate test:")
    local extreme_points = {
        {cx = 1e-10, cy = 1e-10, desc = "very small"},
        {cx = 1e10, cy = 1e10, desc = "very large"},
        {cx = -2.0000001, cy = 0.0, desc = "boundary precision"},
        {cx = -1.9999999, cy = 0.0, desc = "boundary precision"}
    }
    
    for _, point in ipairs(extreme_points) do
        local iterations = mandelbrot_point(point.cx, point.cy, 100)
        print(string.format("Point (%.10f, %.10f) [%s]: %d iterations", 
              point.cx, point.cy, point.desc, iterations))
    end
end

-- Memory usage test
local function mandelbrot_memory_test()
    print("=== Mandelbrot Memory Test ===")
    print("Testing memory usage with large datasets")
    print()
    
    local sizes = {100, 200, 400, 800}
    
    print("Size\tElements\tApprox Memory")
    print("-" .. string.rep("-", 30))
    
    for _, size in ipairs(sizes) do
        local elements = size * size
        local memory_mb = elements * 8 / (1024 * 1024)  -- Assuming 8 bytes per number with NaNbox
        
        print(string.format("%d\t%d\t\t%.2f MB", size, elements, memory_mb))
        
        -- Actually generate to test memory allocation
        if size <= 400 then  -- Avoid too much memory usage
            collectgarbage("collect")
            local mem_before = collectgarbage("count")
            
            local start = os.clock()
            local data = generate_mandelbrot(size, 50)
            local elapsed = os.clock() - start
            
            local mem_after = collectgarbage("count")
            local mem_used = mem_after - mem_before
            
            print(string.format("  Actual memory: %.2f KB, Time: %.3fs", mem_used, elapsed))
        end
    end
    
    print()
end

-- Main execution
if arg and arg[1] then
    local mode = arg[1]
    local size = arg[2] and tonumber(arg[2]) or 200
    local max_iter = arg[3] and tonumber(arg[3]) or 50
    
    if mode == "benchmark" then
        benchmark_mandelbrot(size, max_iter)
    elseif mode == "scaling" then
        mandelbrot_scaling_test()
    elseif mode == "precision" then
        mandelbrot_precision_test()
    elseif mode == "memory" then
        mandelbrot_memory_test()
    else
        print("Usage: luau mandelbrot.lua [benchmark|scaling|precision|memory] [size] [max_iter]")
    end
else
    benchmark_mandelbrot(200, 50)
    print()
    mandelbrot_scaling_test()
    print()
    mandelbrot_precision_test()
    print()
    mandelbrot_memory_test()
end