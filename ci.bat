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
cmake ..
if errorlevel 1 (
  echo [CI][ERROR] CMake configuration failed
  exit /b 1
)

echo [CI] Building project
cmake --build .
if errorlevel 1 (
  echo [CI][ERROR] Build failed
  exit /b 1
)

echo [CI] Running tests (ctest)
ctest --output-on-failure
if errorlevel 1 (
  echo [CI][ERROR] Some tests failed
  exit /b 1
)

echo [CI] All steps completed successfully
exit /b 0
