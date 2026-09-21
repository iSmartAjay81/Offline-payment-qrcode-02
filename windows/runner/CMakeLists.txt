cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Add source files
set(SOURCE_FILES
  "main.cpp"
  "flutter_window.cpp"
  "run_loop.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

add_executable(${BINARY_NAME} WIN32
  ${SOURCE_FILES}
)

# Apply flutter build settings
apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "_HAS_EXCEPTIONS=0")
target_compile_definitions(${BINARY_NAME} PRIVATE UNICODE _UNICODE)

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE ${PLUGIN_LIBRARIES})
