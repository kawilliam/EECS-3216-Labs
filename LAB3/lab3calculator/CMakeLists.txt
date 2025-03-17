cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Initialise pico_sdk from installed location
# (note this can come from environment, CMake cache etc)

# == DO NOT EDIT THE FOLLOWING LINES for the Raspberry Pi Pico VS Code Extension to work ==
if(WIN32)
    set(USERHOME $ENV{USERPROFILE})
else()
    set(USERHOME $ENV{HOME})
endif()
set(sdkVersion 2.1.1)
set(toolchainVersion 14_2_Rel1)
set(picotoolVersion 2.1.1)
set(picoVscode ${USERHOME}/.pico-sdk/cmake/pico-vscode.cmake)
if (EXISTS ${picoVscode})
    include(${picoVscode})
endif()
# ====================================================================================
set(PICO_BOARD pico2_w CACHE STRING "Board type")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(lab3calculator C CXX ASM)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

# -------------------- MAIN APPLICATION --------------------
# Add executable. Default name is the project name, version 0.1
add_executable(lab3calculator lab3calculator.c)

pico_set_program_name(lab3calculator "lab3calculator")
pico_set_program_version(lab3calculator "0.1")

# Enable stdio over USB for debugging
pico_enable_stdio_uart(lab3calculator 0)
pico_enable_stdio_usb(lab3calculator 1)  # Changed from 0 to 1 to enable USB output

# Add the standard library to the build
target_link_libraries(lab3calculator
        pico_stdlib
        hardware_gpio  # Added GPIO for keypad & display
)

# -------------------- TEST APPLICATION --------------------
# Add test executable
add_executable(lab3calculator_test lab3calculator_test.c)

target_compile_definitions(lab3calculator_test PRIVATE CALCULATOR_TEST_MODE=1)

pico_set_program_name(lab3calculator_test "lab3calculator_test")
pico_set_program_version(lab3calculator_test "0.1")

# Enable stdio over USB for test output
pico_enable_stdio_uart(lab3calculator_test 0)
pico_enable_stdio_usb(lab3calculator_test 1)

# Link libraries for test
target_link_libraries(lab3calculator_test
        pico_stdlib
        hardware_gpio
)

# -------------------- COMMON SETTINGS --------------------
# Add the standard include files to the build
target_include_directories(lab3calculator PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}
)

target_include_directories(lab3calculator_test PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}
)

# Generate additional output files
pico_add_extra_outputs(lab3calculator)
pico_add_extra_outputs(lab3calculator_test)