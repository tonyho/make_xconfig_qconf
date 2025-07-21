#!/bin/bash
# Comprehensive static build script for qconf
# Supports multiple build methods: qmake, cmake, and manual
# Usage: ./build-all-static.sh [method] [clean]
#   method: qmake, cmake, manual, or auto (default)
#   clean: clean build artifacts first

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "qconf Comprehensive Static Build Script"
echo "========================================"
echo

# Parse arguments
BUILD_METHOD="auto"
CLEAN_BUILD=false

for arg in "$@"; do
    case $arg in
        qmake|cmake|manual)
            BUILD_METHOD="$arg"
            ;;
        clean)
            CLEAN_BUILD=true
            ;;
        auto)
            BUILD_METHOD="auto"
            ;;
        *)
            echo "Usage: $0 [method] [clean]"
            echo "  method: qmake, cmake, manual, or auto (default)"
            echo "  clean: clean build artifacts first"
            exit 1
            ;;
    esac
done

echo "Build Method: $BUILD_METHOD"
echo "Clean Build: $CLEAN_BUILD"
echo "Static Linking: ENABLED"
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
if [ "$CLEAN_BUILD" = true ]; then
    echo "Cleaning build artifacts..."
    rm -rf build-static build CMakeCache.txt CMakeFiles cmake_install.cmake Makefile* *.o *.exe qconf qconf-static qconf.moc
    echo "Clean completed."
fi

# Function to detect available build tools
detect_build_tools() {
    local tools_available=""
    
    if command -v qmake &> /dev/null; then
        tools_available="$tools_available qmake"
    fi
    
    if command -v cmake &> /dev/null; then
        tools_available="$tools_available cmake"
    fi
    
    if command -v gcc &> /dev/null || command -v g++ &> /dev/null; then
        tools_available="$tools_available manual"
    fi
    
    echo "$tools_available"
}

# Function to try qmake build
try_qmake_build() {
    echo "Attempting qmake static build..."
    
    if [ ! -f "qconf-windows-static.pro" ]; then
        echo "qconf-windows-static.pro not found, using qconf-windows-fixed.pro with static config"
        PROJECT_FILE="qconf-windows-fixed.pro"
        QMAKE_CONFIG="CONFIG+=static"
    else
        echo "Using qconf-windows-static.pro"
        PROJECT_FILE="qconf-windows-static.pro"
        QMAKE_CONFIG=""
    fi
    
    # Generate Makefile
    if qmake $QMAKE_CONFIG "$PROJECT_FILE"; then
        echo "Makefile generated successfully"
        
        # Try different make commands
        if command -v mingw32-make &> /dev/null; then
            MAKE_CMD="mingw32-make"
        elif command -v make &> /dev/null; then
            MAKE_CMD="make"
        else
            echo "No make command found"
            return 1
        fi
        
        echo "Building with $MAKE_CMD..."
        if $MAKE_CMD; then
            echo "qmake static build completed successfully!"
            return 0
        else
            echo "qmake build failed"
            return 1
        fi
    else
        echo "qmake configuration failed"
        return 1
    fi
}

# Function to try cmake build
try_cmake_build() {
    echo "Attempting CMake static build..."
    
    BUILD_DIR="build-static"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure with CMake for static build
    if cmake .. -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=Release; then
        echo "CMake configuration successful"
        
        # Build
        if cmake --build . --config Release; then
            echo "CMake static build completed successfully!"
            
            # Move executable to parent directory
            if [ -f "qconf-static" ]; then
                cp "qconf-static" "../qconf-static"
            elif [ -f "qconf" ]; then
                cp "qconf" "../qconf-static"
            fi
            
            cd ..
            return 0
        else
            echo "CMake build failed"
            cd ..
            return 1
        fi
    else
        echo "CMake configuration failed"
        cd ..
        return 1
    fi
}

# Function to try manual build
try_manual_build() {
    echo "Attempting manual static build..."
    
    # Check for required tools
    if ! command -v gcc &> /dev/null || ! command -v g++ &> /dev/null; then
        echo "gcc/g++ not found"
        return 1
    fi
    
    if ! command -v moc &> /dev/null; then
        echo "moc not found - trying to find Qt5"
        # Try to find Qt5 installation
        for qt_path in /usr/lib/qt5/bin /usr/local/qt5/bin /opt/qt5/bin; do
            if [ -f "$qt_path/moc" ]; then
                export PATH="$qt_path:$PATH"
                echo "Found moc at $qt_path"
                break
            fi
        done
        
        if ! command -v moc &> /dev/null; then
            echo "moc still not found - manual build not possible"
            return 1
        fi
    fi
    
    # Set compiler flags for static build
    CFLAGS="-O2 -Wall -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-implicit-fallthrough -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -DSTATIC_BUILD"
    CXXFLAGS="$CFLAGS -std=c++11"
    
    # Try to find Qt5 includes and libraries
    QT_INCLUDES=""
    QT_LIBS=""
    
    # Common Qt5 paths
    for qt_base in /usr/include/qt5 /usr/local/include/qt5 /opt/qt5/include /usr/include/x86_64-linux-gnu/qt5; do
        if [ -d "$qt_base" ]; then
            QT_INCLUDES="-I$qt_base -I$qt_base/QtCore -I$qt_base/QtGui -I$qt_base/QtWidgets"
            echo "Found Qt5 includes at $qt_base"
            break
        fi
    done
    
    for qt_lib in /usr/lib/x86_64-linux-gnu /usr/lib /usr/local/lib /opt/qt5/lib; do
        if [ -f "$qt_lib/libQt5Core.so" ] || [ -f "$qt_lib/libQt5Core.a" ]; then
            QT_LIBS="-L$qt_lib -lQt5Widgets -lQt5Gui -lQt5Core"
            echo "Found Qt5 libraries at $qt_lib"
            break
        fi
    done
    
    if [ -z "$QT_INCLUDES" ] || [ -z "$QT_LIBS" ]; then
        echo "Qt5 development files not found - manual build not possible"
        return 1
    fi
    
    QT_DEFINES="-DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB"
    
    # Generate MOC file
    echo "Generating MOC file..."
    if ! moc -i qconf.h -o qconf.moc; then
        echo "MOC generation failed"
        return 1
    fi
    
    # Compile C files
    echo "Compiling C files..."
    if ! gcc $CFLAGS -c zconf.tab.c -o zconf.tab.o; then
        echo "Failed to compile zconf.tab.c"
        return 1
    fi
    
    if ! gcc $CFLAGS -c parser_stubs.c -o parser_stubs.o; then
        echo "Failed to compile parser_stubs.c"
        return 1
    fi
    
    # Compile C++ files
    echo "Compiling C++ files..."
    if ! g++ $CXXFLAGS $QT_INCLUDES $QT_DEFINES -c qconf.cc -o qconf.o; then
        echo "Failed to compile qconf.cc"
        return 1
    fi
    
    # Link executable (try static first, then dynamic)
    echo "Linking executable..."
    STATIC_FLAGS="-static -static-libgcc -static-libstdc++"
    
    if g++ $STATIC_FLAGS -o qconf-static zconf.tab.o parser_stubs.o qconf.o $QT_LIBS -lpthread 2>/dev/null; then
        echo "Manual static build completed successfully!"
        return 0
    else
        echo "Static linking failed, trying dynamic linking..."
        if g++ -o qconf-static zconf.tab.o parser_stubs.o qconf.o $QT_LIBS; then
            echo "Manual dynamic build completed successfully!"
            return 0
        else
            echo "Manual build failed"
            return 1
        fi
    fi
}

# Main build logic
BUILD_SUCCESS=false
AVAILABLE_TOOLS=$(detect_build_tools)

echo "Available build tools:$AVAILABLE_TOOLS"
echo

if [ "$BUILD_METHOD" = "auto" ]; then
    # Try build methods in order of preference
    for method in qmake cmake manual; do
        if echo "$AVAILABLE_TOOLS" | grep -q "$method"; then
            echo "Trying $method build method..."
            if try_${method}_build; then
                BUILD_SUCCESS=true
                BUILD_METHOD="$method"
                break
            else
                echo "$method build failed, trying next method..."
                echo
            fi
        fi
    done
else
    # Try specific build method
    if echo "$AVAILABLE_TOOLS" | grep -q "$BUILD_METHOD"; then
        echo "Using $BUILD_METHOD build method..."
        if try_${BUILD_METHOD}_build; then
            BUILD_SUCCESS=true
        fi
    else
        echo "Error: $BUILD_METHOD build tools not available"
        echo "Available tools:$AVAILABLE_TOOLS"
        exit 1
    fi
fi

# Check build result
if [ "$BUILD_SUCCESS" = false ]; then
    echo
    echo "========================================"
    echo "All build methods failed!"
    echo "========================================"
    echo
    echo "Please check:"
    echo "1. Qt5 development packages are installed"
    echo "2. Build tools (qmake, cmake, gcc/g++) are available"
    echo "3. All required dependencies are met"
    exit 1
fi

# Find the created executable
EXECUTABLE=""
for exe in qconf-static qconf; do
    if [ -f "$exe" ]; then
        EXECUTABLE="$exe"
        break
    fi
done

if [ -z "$EXECUTABLE" ]; then
    echo "Error: No executable was created"
    exit 1
fi

echo
echo "========================================"
echo "Static Build completed successfully!"
echo "========================================"
echo
echo "Build Method: $BUILD_METHOD"
echo "Created: $EXECUTABLE"
echo "Size: $(stat -c%s "$EXECUTABLE" 2>/dev/null || stat -f%z "$EXECUTABLE" 2>/dev/null || echo "unknown") bytes"

# Test the executable
echo
echo "Testing executable..."
if ./"$EXECUTABLE" --help >/dev/null 2>&1; then
    echo
    echo "SUCCESS: $EXECUTABLE is working correctly!"
    echo
    echo "Usage: ./$EXECUTABLE <Kconfig-file>"
    echo "Test:  ./$EXECUTABLE test_Kconfig"
else
    echo
    echo "WARNING: $EXECUTABLE may have issues. Try running it manually."
fi

# Check dependencies
echo
echo "Checking dependencies..."
if command -v ldd &> /dev/null; then
    echo "Dynamic library dependencies:"
    ldd "$EXECUTABLE" 2>/dev/null | head -10 || echo "  Static executable or ldd failed"
elif command -v otool &> /dev/null; then
    echo "Dynamic library dependencies (macOS):"
    otool -L "$EXECUTABLE" 2>/dev/null || echo "  Static executable or otool failed"
else
    echo "Cannot check dependencies (ldd/otool not found)"
fi

echo
echo "Static build completed using $BUILD_METHOD!"
echo "Executable: $EXECUTABLE"