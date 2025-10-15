@echo off
setlocal enabledelayedexpansion

REM Robust CI script for Windows: detect toolchain, configure, build, and run tests

echo [CI] Removing existing build directory (if any)
if exist build rmdir /s /q build

REM ci.bat - hardened flow using labels to avoid nested parentheses parsing issues
echo [CI] Removing existing build directory (if any)
if exist build rmdir /s /q build

echo [CI] Creating build directory
mkdir build
if errorlevel 1 (
  echo [CI][ERROR] Failed to create build directory
  exit /b 1
)

echo [CI] Changing to build directory
cd build || (echo [CI][ERROR] Cannot change to build directory && exit /b 1)

set "CMAKE_GENERATOR="
set "CMAKE_ARCH_FLAGS="

:: Prefer MinGW if available
where g++ >nul 2>&1
if %errorlevel%==0 goto USE_MINGW

:: Try to locate Visual Studio via vswhere
where vswhere >nul 2>&1
if %errorlevel%==0 goto TRY_VSWHERE

:: Fallback: check for cl on PATH
where cl >nul 2>&1
if %errorlevel%==0 goto USE_MSVC

echo [CI][ERROR] No supported C++ toolchain found (no g++, no vswhere, no cl.exe).
echo [CI][ERROR] Install MinGW-w64 or Visual Studio (or run this from a Developer Command Prompt).
exit /b 2

:USE_MINGW
set "CMAKE_GENERATOR=MinGW Makefiles"
goto CONFIGURE

:TRY_VSWHERE
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2^>nul`) do set "VS_PATH=%%i"
if defined VS_PATH goto CALL_VSDEV

:: If vswhere did not give us an installation path, fallback to cl check
where cl >nul 2>&1
if %errorlevel%==0 goto USE_MSVC

echo [CI][ERROR] vswhere did not locate a Visual Studio installation and cl.exe is not on PATH.
echo [CI][ERROR] Install Visual Studio or run from Developer Command Prompt.
exit /b 2

:CALL_VSDEV
set "VSDEVCMD=%VS_PATH%\Common7\Tools\VsDevCmd.bat"
if exist "%VSDEVCMD%" (
  echo [CI] Calling VsDevCmd to set up environment
  call "%VSDEVCMD%" -arch=amd64 >nul 2>&1
)

where cl >nul 2>&1
if %errorlevel%==0 goto USE_MSVC

echo [CI][ERROR] cl.exe not found after calling VsDevCmd. Aborting.
exit /b 2

:USE_MSVC
set "CMAKE_GENERATOR=Visual Studio 17 2022"
set "CMAKE_ARCH_FLAGS=-A x64"
goto CONFIGURE

:CONFIGURE
echo [CI] Configuring with CMake generator: %CMAKE_GENERATOR% %CMAKE_ARCH_FLAGS%
cmake -S .. -B . -G "%CMAKE_GENERATOR%" %CMAKE_ARCH_FLAGS%
if errorlevel 1 (
  echo [CI][ERROR] CMake configuration failed
  exit /b 1
)

echo [CI] Building project
if "%CMAKE_GENERATOR%"=="MinGW Makefiles" (
  cmake --build . --parallel %NUMBER_OF_PROCESSORS%
) else (
  cmake --build . --config Debug
)
if errorlevel 1 (
  echo [CI][ERROR] Build failed
  exit /b 1
)

echo [CI] Running tests
if "%CMAKE_GENERATOR%"=="MinGW Makefiles" (
  ctest --output-on-failure
) else (
  ctest --test-dir . -C Debug --output-on-failure
)
if errorlevel 1 (
  echo [CI][ERROR] Some tests failed
  exit /b 1
)

echo [CI] All steps completed successfully
exit /b 0
      ) else (
        :: vswhere not available; try cl directly
        where cl >nul 2>&1
        if %errorlevel%==0 (
          echo [CI] cl.exe is on PATH; using Visual Studio 17 2022 generator
          set "CMAKE_GENERATOR=Visual Studio 17 2022"
          set "CMAKE_ARCH_FLAGS=-A x64"
        ) else (
          echo [CI][ERROR] No supported C++ toolchain found (no g++, no vswhere, no cl.exe).
          echo [CI][ERROR] Install MinGW-w64 or Visual Studio (or run this from a Developer Command Prompt).
          exit /b 2
        )
      )
    )

    echo [CI] Configuring with CMake generator: %CMAKE_GENERATOR% %CMAKE_ARCH_FLAGS%
    cmake -S .. -B . -G "%CMAKE_GENERATOR%" %CMAKE_ARCH_FLAGS%
    if errorlevel 1 (
      echo [CI][ERROR] CMake configuration failed
      exit /b 1
    )

    echo [CI] Building project
    if "%CMAKE_GENERATOR%"=="MinGW Makefiles" (
      cmake --build . -- -j%NUMBER_OF_PROCESSORS%
    ) else (
      cmake --build . --config Debug
    )
    if errorlevel 1 (
      echo [CI][ERROR] Build failed
      exit /b 1
    )

    echo [CI] Running tests
    if "%CMAKE_GENERATOR%"=="MinGW Makefiles" (
      ctest --output-on-failure
    ) else (
      ctest --test-dir . -C Debug --output-on-failure
    )
    if errorlevel 1 (
      echo [CI][ERROR] Some tests failed
      exit /b 1
    )

    echo [CI] All steps completed successfully
    exit /b 0
      echo [CI][ERROR] Some tests failed
