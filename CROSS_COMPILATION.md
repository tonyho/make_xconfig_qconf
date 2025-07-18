# qconf Cross-Compilation Guide

This document provides detailed instructions for cross-compiling qconf for Windows x64 on Linux systems.

## Overview

The qconf standalone build system now supports:
- **Native Linux builds** (x64)
- **Windows x64 cross-compilation** from Linux
- **Automated release packaging** with all dependencies
- **Multiple build systems**: Make, CMake, and comprehensive build scripts

## Quick Start

### Build Everything
```bash
# Build for all platforms and create release packages
./build-all.sh

# Build only for Linux
./build-all.sh --linux-only

# Build only for Windows (requires MinGW-w64)
./build-all.sh --windows-only
```

### Individual Builds
```bash
# Linux native
make linux
make release-linux

# Windows cross-compilation
make win64
make release-win64

# CMake builds
./build-cmake.sh --target linux
./build-cmake.sh --target win64
```

## Prerequisites

### Linux Build Requirements
```bash
# Ubuntu/Debian
sudo apt-get install build-essential qtbase5-dev qtbase5-dev-tools

# Fedora
sudo dnf install gcc gcc-c++ make qt5-qtbase-devel

# Arch Linux
sudo pacman -S base-devel qt5-base qt5-tools
```

### Windows Cross-Compilation Requirements

#### Option 1: Distribution Packages (Recommended)

**Ubuntu/Debian:**
```bash
# Basic MinGW-w64 toolchain
sudo apt-get install mingw-w64 mingw-w64-tools

# Qt5 for MinGW (may require additional repositories)
sudo apt-get install qt5-qmake-bin
```

**Fedora:**
```bash
# Complete MinGW-w64 + Qt5 setup
sudo dnf install mingw64-gcc mingw64-gcc-c++ mingw64-qt5-qtbase-devel mingw64-qt5-qttools
```

**Arch Linux:**
```bash
# MinGW-w64 and Qt5
sudo pacman -S mingw-w64-gcc mingw-w64-qt5-base mingw-w64-qt5-tools
```

#### Option 2: MXE (Cross-platform, most reliable)
```bash
# Clone and build MXE with Qt5
git clone https://github.com/mxe/mxe.git
cd mxe

# Build Qt5 for Windows x64 (takes 30-60 minutes)
make MXE_TARGETS=x86_64-w64-mingw32.shared qt5

# Add to PATH
export PATH="/path/to/mxe/usr/bin:$PATH"
```

## Build Process Details

### Makefile Targets

```bash
# Native builds
make linux          # Build for Linux
make                 # Same as 'make linux'

# Cross-compilation
make win64           # Build for Windows x64

# Release packages
make release-linux   # Create Linux release package
make release-win64   # Create Windows release package  
make release-all     # Create all release packages

# Utilities
make clean           # Clean build artifacts
make install         # Install on Linux (requires sudo)
```

### CMake Cross-Compilation

```bash
# Linux native
mkdir build-linux && cd build-linux
cmake .. -DCMAKE_BUILD_TYPE=Release
make

# Windows cross-compilation
mkdir build-win64 && cd build-win64
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/mingw-w64-x86_64.cmake
make

# Or use the helper script
./build-cmake.sh --target win64 --release
```

## Release Packages

### Linux Release Package Contents
```
qconf-linux-x64-YYYYMMDD/
├── qconf                 # Stripped executable
├── install.sh           # Installation script
├── README.md            # Documentation
├── test_Kconfig         # Test configuration
├── USAGE.txt           # Usage instructions
└── DEPENDENCIES.txt    # Library dependencies
```

### Windows Release Package Contents
```
qconf-windows-x64-YYYYMMDD/
├── qconf.exe           # Main executable
├── qconf.bat           # Batch launcher
├── qconf.ps1           # PowerShell launcher
├── check-deps.bat      # Dependency checker
├── Qt5Core.dll         # Qt5 libraries
├── Qt5Gui.dll
├── Qt5Widgets.dll
├── libgcc_s_seh-1.dll  # MinGW runtime
├── libstdc++-6.dll
├── libwinpthread-1.dll
├── platforms/          # Qt5 platform plugins
│   └── qwindows.dll
├── README.md           # Documentation
├── test_Kconfig        # Test configuration
└── USAGE.txt          # Usage instructions
```

## Troubleshooting

### Common Issues

#### "MinGW Qt5 not found"
```bash
# Check if MinGW-w64 is installed
x86_64-w64-mingw32-gcc --version

# Find Qt5 installations
find /usr -name "*mingw*qt5*" -type d 2>/dev/null
find /usr -name "Qt5Core.dll" 2>/dev/null

# Install missing packages (Fedora example)
sudo dnf install mingw64-qt5-qtbase-devel
```

#### "DLL dependencies missing" (Windows)
The release script automatically copies required DLLs. If manual copying is needed:
```bash
# Find Qt5 DLLs
find /usr -name "Qt5*.dll" 2>/dev/null

# Copy to release directory
cp /path/to/Qt5*.dll releases/qconf-windows-x64-*/
```

#### "Cannot execute binary file" (Linux)
Make sure you're running the correct architecture:
```bash
file qconf                    # Check if it's x64
ldd qconf                     # Check library dependencies
./qconf --help               # Test execution
```

### Build Script Debugging

Enable verbose output:
```bash
# Make with verbose output
make V=1 win64

# Build script with debug info
bash -x ./build-all.sh --windows-only
```

## Advanced Configuration

### Custom Qt5 Paths
```bash
# Set custom Qt5 path for cross-compilation
export QT5_PREFIX="/custom/path/to/mingw-qt5"
make win64
```

### Static Linking (Experimental)
```bash
# Enable static linking in CMake
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/mingw-w64-x86_64.cmake \
         -DCMAKE_EXE_LINKER_FLAGS="-static"
```

### Custom Build Flags
```bash
# Add custom compiler flags
make win64 CXXFLAGS="-O3 -march=native"
```

## Testing Cross-Compiled Binaries

### Using Wine (Linux)
```bash
# Install Wine
sudo apt-get install wine

# Test Windows executable
wine qconf.exe test_Kconfig
```

### On Windows
1. Copy the release package to a Windows system
2. Extract and run `check-deps.bat`
3. Test with: `qconf.exe test_Kconfig`

## Performance Notes

- **Linux builds**: ~30 seconds on modern hardware
- **Windows cross-compilation**: ~45 seconds (first time may be longer)
- **MXE Qt5 build**: 30-60 minutes (one-time setup)
- **Release packaging**: ~10 seconds per platform

## Integration with CI/CD

Example GitHub Actions workflow:
```yaml
name: Build qconf
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y qtbase5-dev mingw-w64
    - name: Build all platforms
      run: ./build-all.sh
    - name: Upload releases
      uses: actions/upload-artifact@v2
      with:
        name: qconf-releases
        path: releases/
```

This cross-compilation setup provides a complete solution for building portable qconf executables for both Linux and Windows platforms.