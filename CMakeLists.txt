cmake_minimum_required(VERSION 3.10)

project(hello VERSION 1.0 LANGUAGES CXX)

# Use C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Place runtime binaries in the build directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Create a library from math_operations.cpp
add_library(math_lib STATIC math_operations.cpp)
target_include_directories(math_lib PUBLIC ${CMAKE_SOURCE_DIR})

# Main executable linked against math_lib
add_executable(hello main.cpp)
target_link_libraries(hello PRIVATE math_lib)

# FetchContent to bring in GoogleTest
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/release-1.12.1.zip
)
# For Windows: ensure CRT settings for gtest match
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Enable CTest and add tests subdirectory
enable_testing()

# If there is a tests/unit_tests.cpp file, create run_tests here and link it to math_lib and gtest_main
if(EXISTS "${CMAKE_SOURCE_DIR}/tests/unit_tests.cpp")
  add_executable(run_tests tests/unit_tests.cpp)
  target_include_directories(run_tests PRIVATE ${CMAKE_SOURCE_DIR})
  target_link_libraries(run_tests PRIVATE math_lib gtest_main)
  add_test(NAME run_tests COMMAND run_tests)
endif()

