#!/bin/bash
# CMake build script for qconf standalone

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
BUILD_TYPE="Release"
TARGET="native"
BUILD_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --debug         Build in debug mode"
            echo "  --release       Build in release mode (default)"
            echo "  --target TARGET Build target (native, win64)"
            echo "  --build-dir DIR Build directory (default: build-TARGET)"
            echo "  --help, -h      Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set default build directory
if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR="build-${TARGET}"
fi

print_status "CMake build configuration:"
print_status "  Target: $TARGET"
print_status "  Build type: $BUILD_TYPE"
print_status "  Build directory: $BUILD_DIR"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake based on target
case "$TARGET" in
    native|linux)
        print_status "Configuring for native Linux build..."
        cmake .. \
            -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -DCMAKE_INSTALL_PREFIX="/usr/local"
        ;;
    win64|windows)
        print_status "Configuring for Windows x64 cross-compilation..."
        
        # Check if toolchain file exists
        if [ ! -f "../cmake/mingw-w64-x86_64.cmake" ]; then
            print_error "MinGW toolchain file not found"
            exit 1
        fi
        
        cmake .. \
            -DCMAKE_TOOLCHAIN_FILE="../cmake/mingw-w64-x86_64.cmake" \
            -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -DCMAKE_INSTALL_PREFIX="/usr/x86_64-w64-mingw32"
        ;;
    *)
        print_error "Unknown target: $TARGET"
        print_error "Supported targets: native, linux, win64, windows"
        exit 1
        ;;
esac

# Build
print_status "Building qconf..."
make -j$(nproc)

# Check result
case "$TARGET" in
    native|linux)
        if [ -f "qconf" ]; then
            print_success "Linux build completed: $BUILD_DIR/qconf"
        else
            print_error "Build failed - executable not found"
            exit 1
        fi
        ;;
    win64|windows)
        if [ -f "qconf.exe" ]; then
            print_success "Windows build completed: $BUILD_DIR/qconf.exe"
        else
            print_error "Build failed - executable not found"
            exit 1
        fi
        ;;
esac

print_success "CMake build completed successfully!"
echo
echo "To install (Linux only):"
echo "  sudo make install"
echo
echo "To test:"
case "$TARGET" in
    native|linux)
        echo "  ./qconf ../test_Kconfig"
        ;;
    win64|windows)
        echo "  wine ./qconf.exe ../test_Kconfig"
        ;;
esac