cmake_minimum_required(VERSION 3.10)
project(qconf)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Cross-compilation support
if(CMAKE_CROSSCOMPILING)
    message(STATUS "Cross-compiling for ${CMAKE_SYSTEM_NAME}")
    
    # Windows-specific settings
    if(WIN32)
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
        set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
        set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
        
        # Add Windows-specific definitions
        add_definitions(-D_WIN32 -DUNICODE -D_UNICODE)
    endif()
endif()

# Find Qt5
find_package(Qt5 REQUIRED COMPONENTS Core Widgets Gui)

# Check if we have the generated parser files
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/zconf.tab.c")
    message(FATAL_ERROR "zconf.tab.c not found. Please run the original build first to generate parser files.")
endif()

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Define sources
set(KCONFIG_SOURCES
    zconf.tab.c
    parser_stubs.c
)

set(QCONF_SOURCES
    qconf.cc
)

# Create kconfig library
add_library(kconfig STATIC ${KCONFIG_SOURCES})
target_compile_definitions(kconfig PRIVATE
    -DPACKAGE="qconf"
    -DLOCALEDIR="/usr/share/locale"
    -DKBUILD_NO_NLS
)

# Generate MOC file
qt5_wrap_cpp(QCONF_MOC qconf.h)

# Create qconf executable
add_executable(qconf ${QCONF_SOURCES} ${QCONF_MOC})
target_link_libraries(qconf kconfig Qt5::Core Qt5::Widgets Qt5::Gui)

# Set compile definitions
target_compile_definitions(qconf PRIVATE
    -DPACKAGE="qconf"
    -DLOCALEDIR="/usr/share/locale"
    -DKBUILD_NO_NLS
)

# Installation
install(TARGETS qconf DESTINATION bin)
