-- Binary Trees benchmark from Computer Language Benchmarks Game
-- Adapted for NaNbox testing

local function BottomUpTree(depth)
    if depth > 0 then
        depth = depth - 1
        local left = BottomUpTree(depth)
        local right = BottomUpTree(depth)
        return {left, right}
    else
        return {0, 0}
    end
end

local function ItemCheck(tree)
    if tree[1] == 0 then
        return 1
    else
        return 1 + ItemCheck(tree[1]) + ItemCheck(tree[2])
    end
end

local function binary_trees_benchmark(n)
    local mindepth = 4
    local maxdepth = math.max(mindepth + 2, n)
    
    local results = {}
    
    -- Stretch tree
    local stretchdepth = maxdepth + 1
    local stretchtree = BottomUpTree(stretchdepth)
    local stretchcheck = ItemCheck(stretchtree)
    table.insert(results, {
        test = "stretch tree",
        depth = stretchdepth,
        check = stretchcheck
    })
    
    -- Long-lived tree
    local longlivedtree = BottomUpTree(maxdepth)
    
    -- Various depth trees
    local depth = mindepth
    while depth <= maxdepth do
        local iterations = 2 ^ (maxdepth - depth + mindepth)
        local check = 0
        
        for i = 1, iterations do
            local temptree = BottomUpTree(depth)
            check = check + ItemCheck(temptree)
        end
        
        table.insert(results, {
            test = "trees",
            iterations = iterations,
            depth = depth,
            check = check
        })
        
        depth = depth + 2
    end
    
    -- Check long-lived tree
    local longlivedcheck = ItemCheck(longlivedtree)
    table.insert(results, {
        test = "long lived tree",
        depth = maxdepth,
        check = longlivedcheck
    })
    
    return results
end

-- Performance timing wrapper
local function time_binary_trees(n)
    local start = os.clock()
    local results = binary_trees_benchmark(n or 16)
    local elapsed = os.clock() - start
    
    print("=== Binary Trees Benchmark ===")
    for _, result in ipairs(results) do
        if result.test == "stretch tree" then
            print(string.format("stretch tree of depth %d\t check: %d", result.depth, result.check))
        elseif result.test == "trees" then
            print(string.format("%d\t trees of depth %d\t check: %d", result.iterations, result.depth, result.check))
        elseif result.test == "long lived tree" then
            print(string.format("long lived tree of depth %d\t check: %d", result.depth, result.check))
        end
    end
    print(string.format("Total time: %.3f seconds", elapsed))
    
    return results, elapsed
end

-- Run the benchmark
if arg and arg[1] then
    time_binary_trees(tonumber(arg[1]))
else
    time_binary_trees(16)
end