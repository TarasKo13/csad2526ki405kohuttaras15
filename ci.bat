@echo off
setlocal enabledelayedexpansion

REM CI script: configure, build, and test with CMake on Windows

echo [CI] Removing existing build directory (if any)
if exist build ( rmdir /s /q build )

echo [CI] Creating build directory
mkdir build
if errorlevel 1 (
  echo [CI][ERROR] Failed to create build directory
  exit /b 1
)

cd build || (echo [CI][ERROR] Cannot change to build directory && exit /b 1)

echo [CI] Configuring project with CMake
  if exist build rmdir /s /q build
if errorlevel 1 (
  echo [CI][ERROR] CMake configuration failed
  mkdir build
  if errorlevel 1 (
    echo [CI][ERROR] Failed to create build directory
    exit /b 1
  )
)

echo [CI] Building project
cmake --build .
  cmake -S . -B build -G "Visual Studio 17 2022" -A x64
  if errorlevel 1 goto :err
  echo [CI][ERROR] Build failed
  exit /b 1
  cmake --build build --config Debug
  if errorlevel 1 goto :err

echo [CI] Running tests (ctest)
  :: Prefer the CTest interface for multi-config builds
  ctest --test-dir build -C Debug --output-on-failure
  if errorlevel 1 goto :err
if errorlevel 1 (
  echo [CI][ERROR] Some tests failed
  echo [CI] Success
  exit /b 0
  exit /b 1
  :err
  echo [CI][ERROR] Build or tests failed
  exit /b 1
)

echo [CI] All steps completed successfully
exit /b 0
