#!/bin/bash
# CMake static build script for qconf
# Usage: ./build-cmake-static.sh [clean]

set -e

echo "========================================"
echo "qconf CMake Static Build Script"
echo "========================================"
echo

# Check if we're in the right directory
if [ ! -f "qconf.cc" ]; then
    echo "Error: qconf.cc not found. Please run this script from the qconf_standalone directory."
    exit 1
fi

# Check for required files
if [ ! -f "zconf.tab.c" ]; then
    echo "Error: zconf.tab.c not found. Please run the original build first to generate parser files."
    exit 1
fi

# Clean build if requested
if [ "$1" = "clean" ]; then
    echo "Cleaning build artifacts..."
    rm -rf build-static CMakeCache.txt CMakeFiles cmake_install.cmake Makefile
    echo "Clean completed."
    if [ $# -eq 1 ]; then
        exit 0
    fi
fi

# Check for CMake
if ! command -v cmake &> /dev/null; then
    echo "Error: cmake not found. Please install CMake."
    exit 1
fi

# Check for Qt5
echo "Checking for Qt5..."
if ! command -v qmake &> /dev/null; then
    echo "Warning: qmake not found in PATH. CMake will try to find Qt5 automatically."
fi

# Create build directory
BUILD_DIR="build-static"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Build environment ready for STATIC BUILD!"
echo "  CMake: $(cmake --version | head -n1)"
echo "  Build Directory: $BUILD_DIR"
echo "  Static Linking: ENABLED"
echo

# Configure with CMake for static build
echo "Configuring with CMake for static build..."
cmake .. -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=Release

if [ $? -ne 0 ]; then
    echo "Error: CMake configuration failed"
    exit 1
fi

# Build
echo "Building with CMake..."
cmake --build . --config Release

if [ $? -ne 0 ]; then
    echo "Error: CMake build failed"
    exit 1
fi

# Check if executable was created
EXECUTABLE=""
if [ -f "qconf-static" ]; then
    EXECUTABLE="qconf-static"
elif [ -f "qconf" ]; then
    EXECUTABLE="qconf"
else
    echo "Error: No executable was created"
    exit 1
fi

# Move executable to parent directory
cp "$EXECUTABLE" "../$EXECUTABLE"
cd ..

echo
echo "========================================"
echo "Static Build completed successfully!"
echo "========================================"
echo
echo "Created: $EXECUTABLE"
echo "Size: $(stat -c%s "$EXECUTABLE" 2>/dev/null || stat -f%z "$EXECUTABLE" 2>/dev/null || echo "unknown") bytes"

# Test the executable
echo
echo "Testing static executable..."
if ./"$EXECUTABLE" --help >/dev/null 2>&1; then
    echo
    echo "SUCCESS: $EXECUTABLE is working correctly!"
    echo
    echo "This is a STATIC executable with minimal external dependencies."
    echo "You can distribute this file with reduced dependency requirements."
    echo
    echo "Usage: ./$EXECUTABLE <Kconfig-file>"
    echo "Test:  ./$EXECUTABLE test_Kconfig"
else
    echo
    echo "WARNING: $EXECUTABLE may have issues. Try running it manually."
fi

# Check dependencies (Linux/macOS)
echo
echo "Checking dependencies..."
if command -v ldd &> /dev/null; then
    echo "Dynamic library dependencies:"
    ldd "$EXECUTABLE" 2>/dev/null || echo "  Static executable or ldd failed"
elif command -v otool &> /dev/null; then
    echo "Dynamic library dependencies (macOS):"
    otool -L "$EXECUTABLE" 2>/dev/null || echo "  Static executable or otool failed"
else
    echo "Cannot check dependencies (ldd/otool not found)"
fi

echo
echo "Static build completed!"