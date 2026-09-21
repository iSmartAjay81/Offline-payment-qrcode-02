cmake_minimum_required(VERSION 3.14)
project(offline_payment_qr LANGUAGES CXX)

set(BINARY_NAME "offline_payment_qr")

cmake_policy(SET CMP0079 NEW)

# Configure build options
option(BUILD_STANDALONE "Build a standalone executable" ON)

# Configure output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/runner")

# Include Flutter build rules
include(flutter/generated_plugins.cmake)

# Application build
add_subdirectory(runner)
