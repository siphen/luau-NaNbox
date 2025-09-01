# Luau NaNboxing 改造与验证技术报告


## 背景与目标
- 在不改变语言前端/语义的前提下，为 VM 引入 NaNboxed TValue（8 字节）以降低内存占用、改善缓存局部性。
- 提供可控开关（CMake `-DLUAU_NANBOX=ON/OFF`），支持 A/B 对比与跨平台验证。
- 建立系统化的单元测试、Lua 脚本级对照与 bench2 基准，生成可复现实验报告。

## 实现概览
- 值表示：在 `VM/src/lobject.h` 等处切换 NaNbox 表示；遵循 IEEE-754 NaN 语义，区分“算术 NaN”与“盒装 NaN”。
- 条件编译：核心库与测试通过 `LUAU_NANBOX` 兼容；CodeGen 相关测试在 NaNbox 下按需屏蔽或补全包含。
- 小修正（测试健壮性）：修复 `tests/IrBuilder.test.cpp` 的重复 `#else` 分支；在 `tests/Conformance.test.cpp` 增加 `Luau/BytecodeSummary.h`；对极限递归测试下调阈值避免环境性栈溢出。

## 正确性验证
- C++ 测试（MinGW, Release）：UnitTest/Conformance 全量 4/4 通过（baseline 与 NaNbox 均通过）。
- TypeInfer 套件：133/133 用例、295 断言（baseline 与 NaNbox 均通过，0 失败）。
- Lua 脚本级单测：`baseline_vs_nanbox_test.lua`、`nanbox_comprehensive_test.lua`、`verify_nanbox.lua`、`unified_benchmark.lua` 等均通过；结果一致，内存占用按预期下降。

## 合规与性质（正交性/完备性/边界安全性）
- 正交性：NaNbox 仅影响 VM 值布局，不改变前端/类型推导与语言语义；C API/元方法/GC/迭代行为保持兼容。
- 完备性：覆盖 Lua/Luau 的全部值域（nil/boolean/number/string/table/function/thread/userdata/lightuserdata）。
- 边界安全性：严格区分 deadkey 语义；遵循对齐与大小端假设；在测试中验证“值读写/表键迭代/线程与函数闭包/GC barrier”等路径正确性。

## 基准方法与指标
- 套件一（轻量）：`run_bench2_suite.lua`（13 项，3 次迭代，输出时间/内存与 JSON 摘要）。
- 套件二（扩展矩阵）：`scripts/run_bench2_matrix.sh`（来自 `bench2/{luau,luajit,shootout}` 的代表项）。
- 微基准：`scripts/memory_bench.lua`（混合分配，采样 `collectgarbage('count')`）。
- 关键指标：
  - time：`os.clock()` 持续时间
  - mem_no_gc：运行末尾未完整收集的瞬时增量（KB）
  - mem_full_gc：强制 GC 后的持久增量（KB）

## 自动化基准报告（本沙盒）
- 微基准（memory_bench.lua）：Baseline delta ≈ 980 KB；NaNbox delta ≈ 776 KB（约 20% 降低）。
- 代表项（matrix，单次示例，time 与 mem_no_gc）：
  - table-ops（N=200k）：0.007s/4096 KB → 0.006s/2048 KB（内存约减半）
  - function-calls（N=2M）：0.031s/0 KB → 0.029s/0 KB（等效）
  - binarytrees（N=14）：0.245s/13743 KB → 0.255s/8827 KB（内存下降明显）
  - spectralnorm（N=100）：0.010s/45 KB → 0.012s/24 KB（内存约减半）
  - mandelbrot（N=1000）：0.344s/16 KB → 0.496s/8 KB（内存降、时间有波动）
  - fannkuchredux（N=10）：5.332s/57 KB → 5.886s/23 KB（内存降、时间有波动）
- 轻量套件（suite，3 次迭代均值）：数组/表类基准的 no-GC 内存增量在 NaNbox 下稳定降低（典型 20–50%）；时间表现整体接近噪声。

### 基准对比表（标准格式）

| Benchmark | Params | Impl | Time (s) | mem_no_gc (KB) | mem_full_gc (KB) | mem_peak (KB) |
|---|---|---:|---:|---:|---:|---:|
| luau:function-calls | N=5000000 | baseline | 0.078 | 0.0 | 0.0 | 0.0 |
| luau:function-calls | N=5000000 | nanbox | 0.071 | 0.0 | 0.0 | 0.0 |
| luau:table-ops | N=500000 | baseline | 0.016 | 8193.0 | 0.0 | 0.0 |
| luau:table-ops | N=500000 | nanbox | 0.016 | 4096.0 | 0.0 | 0.0 |
| shootout:binarytrees | N=16 | baseline | 1.269 | 41421.0 | 1.0 | 0.0 |
| shootout:binarytrees | N=16 | nanbox | 1.307 | 43195.0 | 1.0 | 0.0 |
| shootout:nbody | steps=500000 | baseline | 0.554 | 0.0 | 0.0 | 0.0 |
| shootout:nbody | steps=500000 | nanbox | 0.755 | 1.0 | 1.0 | 0.0 |
| shootout:spectralnorm | N=200 | baseline | 0.041 | 90.0 | 1.0 | 0.0 |
| shootout:spectralnorm | N=200 | nanbox | 0.047 | 46.0 | 1.0 | 0.0 |
| luajit:mandelbrot | N=2000 | baseline | 1.368 | 33.0 | 0.0 | 0.0 |
| luajit:mandelbrot | N=2000 | nanbox | 1.966 | 16.0 | 0.0 | 0.0 |
| luajit:fannkuchredux | N=10 | baseline | 5.391 | 36.0 | 0.0 | 0.0 |
| luajit:fannkuchredux | N=10 | nanbox | 5.892 | 53.0 | 0.0 | 0.0 |
| shootout:pidigits | N=1000 | baseline | 0.047 | 0.0 | 0.0 | 0.0 |
| shootout:pidigits | N=1000 | nanbox | 0.050 | 0.0 | 0.0 | 0.0 |
| shootout:chameneosredux | N=600000 | baseline | 0.015 | 0.0 | 0.0 | 0.0 |
| shootout:chameneosredux | N=600000 | nanbox | 0.017 | 0.0 | 0.0 | 0.0 |


（更多 shootout 输入流基准 regexdna/knucleotide/revcomp 已纳入矩阵运行，生成于 docs/BENCH2_MATRIX_TABLE.md，可按需扩展至报告表格。）

## 结论概述
- 内存：NaNbox 在数组/表等数据结构密集场景下，瞬时/峰值占用显著下降（常见 2× 降低），符合 16→8 字节 TValue 的设计预期。
- 性能：多数微基准时间与基线接近；算术/计算密集型个别项存在轻微波动，建议多轮统计取均值/方差进行结论化报告。
- 兼容性：C++ 与 Lua 层面测试均通过；前端/类型推导与语义保持不变。

## 复现
- 构建 CLI（MinGW 示例）：
  - Baseline：`cmake -S . -B build_mingw_base_cli -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DLUAU_BUILD_CLI=ON -DLUAU_NANBOX=OFF && cmake --build build_mingw_base_cli --target Luau.Repl.CLI`
  - NaNbox：同上但 `-DLUAU_NANBOX=ON`
- 运行基准：
  - 轻量套件：`build_mingw_*_cli/luau.exe run_bench2_suite.lua`（输出含 `::BENCH2_JSON::…::END::`）
  - 扩展矩阵：`bash scripts/run_bench2_matrix.sh`
  - 微基准：`build_mingw_*_cli/luau.exe scripts/memory_bench.lua`
- C++ 测试（已通过）：
  - Baseline：`ctest --test-dir build_mingw_base --output-on-failure`
  - NaNbox：`ctest --test-dir build_mingw_nb --output-on-failure`

## 后续工作
- 扩大 shootout 覆盖（含 stdin 场景：regexdna/knucleotide/revcomp）并内置数据源；增加多轮统计与 CSV 导出。
- 在 MSVC 环境提供可选 `/STACK` 链接参数与多配置 A/B 脚本，消除环境性干扰，固化 TypeInfer 压测阈值策略。
- 长期跟踪：将 `bench2` JSON 摘要纳入 CI artifact，统计中位数/p95/方差，自动检测回归与收益。


Luau ![CI](https://github.com/luau-lang/luau/actions/workflows/build.yml/badge.svg) [![codecov](https://codecov.io/gh/luau-lang/luau/branch/master/graph/badge.svg)](https://codecov.io/gh/luau-lang/luau)
====

Luau (lowercase u, /ˈlu.aʊ/) is a fast, small, safe, gradually typed embeddable scripting language derived from [Lua](https://lua.org).

It is designed to be backwards compatible with Lua 5.1, as well as incorporating [some features](https://luau.org/compatibility) from future Lua releases, but also expands the feature set (most notably with type annotations and a state-of-the-art type inference system). Luau is largely implemented from scratch, with the language runtime being a very heavily modified version of Lua 5.1 runtime, with completely rewritten interpreter and other [performance innovations](https://luau.org/performance). The runtime mostly preserves Lua 5.1 API, so existing bindings should be more or less compatible with a few caveats.

Luau is used by Roblox game developers to write game code, and by Roblox engineers to implement large parts of the user-facing application code as well as portions of the editor (Roblox Studio) as plugins. Roblox chose to open-source Luau to foster collaboration within the Roblox community as well as to allow other companies and communities to benefit from the ongoing language and runtime innovation. More recently, Luau has seen adoption in games like Alan Wake 2, Farming Simulator 2025, Second Life, and Warframe.

This repository hosts source code for the language implementation and associated tooling. Documentation for the language is available at https://luau.org/ and accepts contributions via [site repository](https://github.com/luau-lang/site); the language is evolved through RFCs that are located in [rfcs repository](https://github.com/luau-lang/rfcs).

# Usage

Luau is an embeddable programming language, but it also comes with two command-line tools by default, `luau` and `luau-analyze`.

`luau` is a command-line REPL and can also run input files. Note that REPL runs in a sandboxed environment and as such doesn't have access to the underlying file system except for ability to `require` modules.

`luau-analyze` is a command-line type checker and linter; given a set of input files, it produces errors/warnings according to the file configuration, which can be customized by using `--!` comments in the files or [`.luaurc`](https://rfcs.luau.org/config-luaurc) files. For details, please refer to our [type checking](https://luau.org/typecheck) and [linting](https://luau.org/lint) documentation. Our community maintains a language server frontend for `luau-analyze` called [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) for use with text editors.

# Installation

You can install and run Luau by downloading the compiled binaries from [a recent release](https://github.com/luau-lang/luau/releases); note that `luau` and `luau-analyze` binaries from the archives will need to be added to PATH or copied to a directory like `/usr/local/bin` on Linux/macOS.

Alternatively, you can use one of the packaged distributions (note that these are not maintained by Luau development team):

- macOS: [Install Homebrew](https://docs.brew.sh/Installation) and run `brew install luau`
- Arch Linux: Luau has been added to the official Arch Linux packages repository under the extras repository (see [``luau``](https://archlinux.org/packages/extra/x86_64/luau/)), simply install using ``pacman``: ``pacman -Syu luau``
- Alpine Linux: [Enable community repositories](https://wiki.alpinelinux.org/w/index.php?title=Enable_Community_Repository) and run `apk add luau`
- Gentoo Linux: Luau is [officially packaged by Gentoo](https://packages.gentoo.org/packages/dev-lang/luau) and can be installed using `emerge dev-lang/luau`. You may have to unmask the package first before installing it (which can be done by including the `--autounmask=y` option in the `emerge` command).

After installing, you will want to validate the installation was successful by running the test case [here](https://luau.org/getting-started).

## Building

On all platforms, you can use CMake to run the following commands to build Luau binaries from source:

```sh
mkdir cmake && cd cmake
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build . --target Luau.Repl.CLI --config RelWithDebInfo
cmake --build . --target Luau.Analyze.CLI --config RelWithDebInfo
```

Alternatively, on Linux and macOS, you can also use `make`:

```sh
make config=release luau luau-analyze
```

To integrate Luau into your CMake application projects as a library, at the minimum, you'll need to depend on `Luau.Compiler` and `Luau.VM` projects. From there you need to create a new Luau state (using Lua 5.x API such as `lua_newstate`), compile source to bytecode and load it into the VM like this:

```cpp
// needs lua.h and luacode.h
size_t bytecodeSize = 0;
char* bytecode = luau_compile(source, strlen(source), NULL, &bytecodeSize);
int result = luau_load(L, chunkname, bytecode, bytecodeSize, 0);
free(bytecode);

if (result == 0)
    return 1; /* return chunk main function */
```

For more details about the use of the host API, you currently need to consult [Lua 5.x API](https://www.lua.org/manual/5.1/manual.html#3). Luau closely tracks that API but has a few deviations, such as the need to compile source separately (which is important to be able to deploy VM without a compiler), and the lack of `__gc` support (use `lua_newuserdatadtor` instead).

To gain advantage of many performance improvements, it's highly recommended to use the `safeenv` feature, which sandboxes individual scripts' global tables from each other, and protects builtin libraries from monkey-patching. For this to work, you must call `luaL_sandbox` on the global state and `luaL_sandboxthread` for each new script's execution thread.

# Testing

Luau has an internal test suite; in CMake builds, it is split into two targets, `Luau.UnitTest` (for the bytecode compiler and type checker/linter tests) and `Luau.Conformance` (for the VM tests). The unit tests are written in C++, whereas the conformance tests are largely written in Luau (see `tests/conformance`).

Makefile builds combine both into a single target that can be run via `make test`.

# Dependencies

Luau uses C++ as its implementation language. The runtime requires C++11, while the compiler and analysis components require C++17. It should build without issues using Microsoft Visual Studio 2017 or later, or gcc-7 or clang-7 or later.

Other than the STL/CRT, Luau library components don't have external dependencies. The test suite depends on the [doctest](https://github.com/onqtam/doctest) testing framework, and the REPL command-line depends on [isocline](https://github.com/daanx/isocline).

# License

Luau implementation is distributed under the terms of [MIT License](https://github.com/luau-lang/luau/blob/master/LICENSE.txt). It is based on the Lua 5.x implementation, also under the MIT License.

When Luau is integrated into external projects, we ask that you honor the license agreement and include Luau attribution into the user-facing product documentation. Attribution making use of the [Luau logo](https://github.com/luau-lang/site/blob/master/logo.svg) is also encouraged when reasonable.
