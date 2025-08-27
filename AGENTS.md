# Repository Guidelines

## Project Structure & Module Organization
- `Compiler/`, `VM/`, `Analysis/`, `Ast/`, `CodeGen/`, `EqSat/`, `Config/`, `Common/`: core C++ libraries for the language, VM, analysis, and tooling.
- `CLI/`: command-line tools (`luau`, `luau-analyze`, etc.).
- `Require/`: module resolution runtime and navigator.
- `tests/`: doctest-based unit and conformance tests (`*.test.cpp`, `tests/conformance/`).
- `extern/`: third-party deps (e.g., `isocline`). `bench/`, `fuzz/`, `tools/`: benchmarks, fuzzers, utilities.

## Build, Test, and Development Commands
- CMake (portable):
  - `mkdir cmake && cd cmake && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo`
  - `cmake --build . --target Luau.Repl.CLI && cmake --build . --target Luau.Analyze.CLI`
- Make (Linux/macOS):
  - Build CLIs: `make config=release luau luau-analyze`
  - Run tests: `make test` (runs combined unit+conformance suite)
  - Conformance only: `make conformance`
  - Format code: `make format` (requires `clang-format-11`)

## Coding Style & Naming Conventions
- C++: 4-space indent, tabs disallowed, Allman braces. Column limit 150, left-aligned pointers.
- Follow `.clang-format` (LLVM base). Run `make format` before committing.
- Headers use `#pragma once` and live next to sources (`.h` with `.cpp`).
- Tests use `CamelCase.test.cpp` and doctest sections for clarity.

## Testing Guidelines
- Framework: [doctest]. Add unit tests in `tests/*.test.cpp` near relevant areas; conformance cases under `tests/conformance/`.
- Run locally: `make test` or build CMake targets `Luau.UnitTest` and `Luau.Conformance`.
- Behavior changes should include tests; prefer focused cases with clear names. Optional coverage: `make coverage` (requires LLVM tooling).

## Commit & Pull Request Guidelines
- Commit messages: short imperative subject; optionally include scope and PR ref, e.g., `Fix fuzzer build on NO_TESTS (#1830)` or sync-style `Sync to upstream/release/688 (#1968)`.
- PRs: include summary, motivation, and risks; link issues; add tests for fixes/features; update docs when user-visible.
- CI must pass. Run `make format` and local tests before pushing.

## Security & Configuration Tips
- Report vulnerabilities via `SECURITY.md`; do not disclose publicly.
- Analyzer configuration: use `--!` pragmas or project `.luaurc` files for `luau-analyze`.
- The `luau` REPL runs in a sandbox; file access is restricted by design.

