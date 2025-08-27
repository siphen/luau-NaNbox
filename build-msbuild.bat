@echo off
setlocal enableextensions enabledelayedexpansion

REM build-msbuild.bat [Config] [Platform] [run]
REM - Config: Debug | RelWithDebInfo | Release (default: RelWithDebInfo)
REM - Platform: x64 | Win32 (default: x64)
REM - Third arg 'run' executes the built test binaries
REM Environment overrides:
REM - MSBUILD_EXE: full path to MSBuild.exe
REM - WERROR=ON to enable -DLUAU_WERROR=ON

if not defined MSBUILD_EXE (
    set "MSBUILD_EXE=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
)

set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=RelWithDebInfo"

set "PLATFORM=%~2"
if "%PLATFORM%"=="" set "PLATFORM=x64"

if /I "%WERROR%"=="ON" (
    set "WERROR_FLAG=-DLUAU_WERROR=ON"
)

echo [Configure] CMake generator for VS2019, Config=%CONFIG%, Platform=%PLATFORM%
cmake -S . -B cmake-build -G "Visual Studio 16 2019" -A %PLATFORM% -DCMAKE_BUILD_TYPE=%CONFIG% -DLUAU_BUILD_TESTS=ON %WERROR_FLAG%
if errorlevel 1 goto :error

echo [Build] Targets: Luau.UnitTest;Luau.Conformance
"%MSBUILD_EXE%" cmake-build\Luau.sln /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /m /v:m /t:Luau.UnitTest;Luau.Conformance
if errorlevel 1 goto :error

if /I "%~3"=="run" (
    echo [Run] Luau.UnitTest
    if exist "cmake-build\%CONFIG%\Luau.UnitTest.exe" (
        "cmake-build\%CONFIG%\Luau.UnitTest.exe"
    ) else (
        echo ERROR: Not found: cmake-build\%CONFIG%\Luau.UnitTest.exe
    )

    echo [Run] Luau.Conformance
    if exist "cmake-build\%CONFIG%\Luau.Conformance.exe" (
        "cmake-build\%CONFIG%\Luau.Conformance.exe"
    ) else (
        echo ERROR: Not found: cmake-build\%CONFIG%\Luau.Conformance.exe
    )
)

echo Done.
exit /b 0

:error
echo.
echo Build failed. Make sure you are using "x64 Native Tools Command Prompt for VS 2019/2022" and MSBuild is installed.
echo Current MSBuild: "%MSBUILD_EXE%"
exit /b 1

