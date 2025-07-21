cmake_minimum_required(VERSION 3.10)
project(qconf)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static linking option
option(BUILD_STATIC "Build with static linking" OFF)

if(BUILD_STATIC)
    message(STATUS "Building with static linking")
    
    # Prefer static libraries when available
    set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
endif()

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

# Set compile definitions
target_compile_definitions(qconf PRIVATE
    -DPACKAGE="qconf"
    -DLOCALEDIR="/usr/share/locale"
    -DKBUILD_NO_NLS
    -DQT_MOC_CPP  # Prevent qconf.cc from including MOC file directly
)

# Link libraries based on build type
if(BUILD_STATIC)
    target_compile_definitions(qconf PRIVATE -DSTATIC_BUILD)
    
    # Check if static Qt5 libraries are available
    find_library(QT5_WIDGETS_STATIC libQt5Widgets.a HINTS ${Qt5Widgets_DIR}/../../../lib ${Qt5Widgets_DIR}/../../lib)
    find_library(QT5_GUI_STATIC libQt5Gui.a HINTS ${Qt5Gui_DIR}/../../../lib ${Qt5Gui_DIR}/../../lib)
    find_library(QT5_CORE_STATIC libQt5Core.a HINTS ${Qt5Core_DIR}/../../../lib ${Qt5Core_DIR}/../../lib)
    
    if(QT5_WIDGETS_STATIC AND QT5_GUI_STATIC AND QT5_CORE_STATIC)
        message(STATUS "Found static Qt5 libraries - using full static linking")
        target_compile_definitions(qconf PRIVATE -DQT_STATICPLUGIN)
        
        # Link with kconfig and static Qt5 libraries
        target_link_libraries(qconf kconfig ${QT5_WIDGETS_STATIC} ${QT5_GUI_STATIC} ${QT5_CORE_STATIC})
        
        # Windows-specific static libraries
        if(WIN32)
            target_link_libraries(qconf 
                -static -static-libgcc -static-libstdc++
                ws2_32 ole32 oleaut32 uuid winmm gdi32 comdlg32 
                imm32 shell32 kernel32 user32 advapi32 winspool 
                comctl32 rpcrt4 msimg32 opengl32 glu32 usp10
            )
            
            # Try to link Qt5 platform plugins statically
            find_library(QT5_QWINDOWS_LIB qwindows HINTS ${Qt5_DIR}/../../../plugins/platforms)
            if(QT5_QWINDOWS_LIB)
                target_link_libraries(qconf ${QT5_QWINDOWS_LIB})
            endif()
            
            find_library(QT5_QWINDOWSVISTA_LIB qwindowsvistastyle HINTS ${Qt5_DIR}/../../../plugins/styles)
            if(QT5_QWINDOWSVISTA_LIB)
                target_link_libraries(qconf ${QT5_QWINDOWSVISTA_LIB})
            endif()
        else()
            # Linux static linking with additional libraries
            target_link_libraries(qconf -static-libgcc -static-libstdc++ -lpthread)
        endif()
    else()
        message(STATUS "Static Qt5 libraries not found - using dynamic linking with static runtime")
        
        # Fall back to dynamic Qt5 with static runtime libraries
        target_link_libraries(qconf kconfig Qt5::Core Qt5::Widgets Qt5::Gui)
        
        if(WIN32)
            target_link_libraries(qconf -static-libgcc -static-libstdc++)
        else()
            target_link_libraries(qconf -static-libgcc -static-libstdc++)
        endif()
    endif()
    
    # Set output name for static build
    set_target_properties(qconf PROPERTIES OUTPUT_NAME "qconf-static")
else()
    # Dynamic build
    target_link_libraries(qconf kconfig Qt5::Core Qt5::Widgets Qt5::Gui)
endif()

# Installation
install(TARGETS qconf DESTINATION bin)
