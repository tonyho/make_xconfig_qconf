#!/bin/bash
# Comprehensive build script for qconf standalone
# Builds for Linux and Windows x64, creates release packages

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for required tools
    local missing_tools=()
    
    for tool in gcc g++ make pkg-config; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install build essentials and try again."
        exit 1
    fi
    
    # Check for Qt5
    if ! pkg-config --exists Qt5Core Qt5Gui Qt5Widgets; then
        print_error "Qt5 development packages not found."
        print_error "Please install Qt5 development packages:"
        print_error "  Ubuntu/Debian: sudo apt-get install qtbase5-dev qtbase5-dev-tools"
        print_error "  CentOS/RHEL:   sudo yum install qt5-qtbase-devel"
        print_error "  Fedora:        sudo dnf install qt5-qtbase-devel"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Check MinGW for Windows cross-compilation
check_mingw() {
    print_status "Checking MinGW-w64 for Windows cross-compilation..."
    
    if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
        print_warning "MinGW-w64 not found. Windows cross-compilation will be skipped."
        print_warning "To enable Windows builds, install:"
        print_warning "  Ubuntu/Debian: sudo apt-get install mingw-w64 mingw-w64-tools"
        print_warning "  Fedora:        sudo dnf install mingw64-gcc mingw64-gcc-c++"
        return 1
    fi
    
    # Check for MinGW Qt5
    local qt5_found=false
    local qt5_paths=(
        "/usr/x86_64-w64-mingw32"
        "/usr/lib/mxe/usr/x86_64-w64-mingw32.shared"
        $(find /usr -name "*mingw*qt5*" -type d 2>/dev/null | head -5)
    )
    
    for path in "${qt5_paths[@]}"; do
        if [ -f "$path/lib/libQt5Core.a" ] || [ -f "$path/lib/Qt5Core.dll" ]; then
            qt5_found=true
            break
        fi
    done
    
    if [ "$qt5_found" = false ]; then
        print_warning "MinGW Qt5 not found. Windows cross-compilation will be skipped."
        print_warning "To enable Windows builds, install:"
        print_warning "  Ubuntu/Debian: sudo apt-get install qt5-qmake-bin (may need PPA)"
        print_warning "  Fedora:        sudo dnf install mingw64-qt5-qtbase-devel"
        print_warning "  Or build Qt5 with MXE: https://mxe.cc/"
        return 1
    fi
    
    print_success "MinGW-w64 and Qt5 found"
    return 0
}

# Build for Linux
build_linux() {
    print_status "Building qconf for Linux x64..."
    
    make clean
    make linux
    
    if [ -f "qconf" ]; then
        print_success "Linux build completed: qconf"
        
        # Test the executable
        if ./qconf --help >/dev/null 2>&1; then
            print_success "Linux executable test passed"
        else
            print_warning "Linux executable test failed (may need display)"
        fi
    else
        print_error "Linux build failed"
        return 1
    fi
}

# Build for Windows
build_windows() {
    print_status "Building qconf for Windows x64..."
    
    make clean
    if make win64; then
        if [ -f "qconf.exe" ]; then
            print_success "Windows build completed: qconf.exe"
            
            # Check if it's a valid PE executable
            if file qconf.exe | grep -q "PE32+"; then
                print_success "Windows executable validation passed"
            else
                print_warning "Windows executable validation failed"
            fi
        else
            print_error "Windows build failed - executable not found"
            return 1
        fi
    else
        print_error "Windows build failed"
        return 1
    fi
}

# Create releases
create_releases() {
    print_status "Creating release packages..."
    
    # Clean old releases
    rm -rf releases/
    
    # Create Linux release if executable exists
    if [ -f "qconf" ]; then
        print_status "Creating Linux release package..."
        make release-linux
        print_success "Linux release package created"
    fi
    
    # Create Windows release if executable exists
    if [ -f "qconf.exe" ]; then
        print_status "Creating Windows release package..."
        make release-win64
        print_success "Windows release package created"
    fi
    
    # List created releases
    if [ -d "releases" ]; then
        print_success "Release packages created:"
        ls -la releases/*.{tar.gz,zip} 2>/dev/null || true
    fi
}

# Main build process
main() {
    echo "========================================"
    echo "qconf Standalone Build Script"
    echo "========================================"
    echo
    
    # Parse command line arguments
    local build_linux=true
    local build_windows=true
    local create_release=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --linux-only)
                build_windows=false
                shift
                ;;
            --windows-only)
                build_linux=false
                shift
                ;;
            --no-release)
                create_release=false
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --linux-only    Build only for Linux"
                echo "  --windows-only  Build only for Windows"
                echo "  --no-release    Skip creating release packages"
                echo "  --help, -h      Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Build for Linux
    if [ "$build_linux" = true ]; then
        if build_linux; then
            print_success "Linux build successful"
        else
            print_error "Linux build failed"
            exit 1
        fi
    fi
    
    # Build for Windows
    if [ "$build_windows" = true ]; then
        if check_mingw; then
            if build_windows; then
                print_success "Windows build successful"
            else
                print_warning "Windows build failed, continuing..."
            fi
        else
            print_warning "Skipping Windows build due to missing dependencies"
        fi
    fi
    
    # Create release packages
    if [ "$create_release" = true ]; then
        create_releases
    fi
    
    echo
    print_success "Build process completed!"
    echo
    echo "Built executables:"
    [ -f "qconf" ] && echo "  - qconf (Linux x64)"
    [ -f "qconf.exe" ] && echo "  - qconf.exe (Windows x64)"
    echo
    
    if [ -d "releases" ]; then
        echo "Release packages:"
        ls releases/ | sed 's/^/  - /'
    fi
}

# Run main function with all arguments
main "$@"