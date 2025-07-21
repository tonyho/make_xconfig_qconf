# Standalone qconf Build

This directory contains all the necessary files to build qconf (Qt-based Kconfig configurator) independently from the main project.

## Prerequisites

### Linux
- Qt5 development packages:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install qtbase5-dev qtbase5-dev-tools
  
  # CentOS/RHEL/Fedora
  sudo yum install qt5-qtbase-devel
  # or
  sudo dnf install qt5-qtbase-devel
  ```

### Windows
- Qt5 SDK with MinGW or MSVC compiler
- Add Qt5 bin directory to PATH

## Building

### Static Builds (Recommended for Distribution)

For creating standalone executables with minimal dependencies:

**Windows:**
```batch
# Dedicated static build scripts
build-windows-static.bat
# or
.\build-windows-static.ps1
```

**Linux/Unix:**
```bash
# Comprehensive static build (auto-detects best method)
./build-all-static.sh

# Specific methods
./build-all-static.sh qmake
./build-all-static.sh cmake
./build-all-static.sh manual
```

📖 **See [Static Build Guide](STATIC_BUILD_GUIDE.md) for detailed instructions**

### Quick Start - All Platforms
```bash
# Build for all supported platforms and create release packages
./build-all.sh

# Build only for Linux
./build-all.sh --linux-only

# Build only for Windows (requires MinGW-w64)
./build-all.sh --windows-only
```

### Linux Native Build
```bash
# Using Make
make
# or
make linux

# Using CMake
mkdir build && cd build
cmake .. && make
# or
./build-cmake.sh --target native
```

### Windows Cross-Compilation (Linux → Windows)
```bash
# Prerequisites (Ubuntu/Debian):
sudo apt-get install mingw-w64 mingw-w64-tools
# For Qt5 MinGW, you may need additional packages or MXE

# Using Make
make win64

# Using CMake
./build-cmake.sh --target win64
```

### Windows Native Build
```cmd
# Recommended: Enhanced build script with auto-detection
build-windows-native.bat

# Alternative: PowerShell script (most robust)
.\build-windows.ps1

# Simple: qmake-based build
build_windows.bat

# Manual: Using qmake project file
qmake qconf-windows.pro && mingw32-make
```

**For Windows build issues (like "ld returned 5 exit status"), see [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md)**

## Release Packages

### Creating Release Packages
```bash
# Create release packages for all platforms
make release-all

# Create Linux release package only
make release-linux

# Create Windows release package only  
make release-win64
```

Release packages include:
- **Linux**: Statically linked executable with installation script
- **Windows**: Executable with all required Qt5 DLLs and runtime libraries

### Using Pre-built Releases
1. Download the appropriate release package for your platform
2. Extract the archive
3. Follow the included USAGE.txt instructions

## Installation

### Linux
```bash
# From source
sudo make install

# From release package
cd qconf-linux-x64-YYYYMMDD/
./install.sh                    # Install to /usr/local/bin
./install.sh ~/bin              # Install to ~/bin
```

### Windows
1. Extract the release package to any directory (e.g., `C:\Tools\qconf`)
2. Optionally add the directory to your PATH environment variable
3. Run `check-deps.bat` to verify all dependencies are present

## Usage

After building or installing, you can use qconf to configure any Kconfig-based project:

```bash
# Linux
./qconf /path/to/Kconfig
qconf /path/to/Kconfig          # If installed

# Windows
qconf.exe Kconfig
qconf.bat Kconfig               # Using batch wrapper
.\qconf.ps1 Kconfig             # Using PowerShell wrapper
```

## Cross-Compilation Requirements

### For Windows x64 Cross-Compilation on Linux

#### Ubuntu/Debian:
```bash
# Basic MinGW-w64 toolchain
sudo apt-get install mingw-w64 mingw-w64-tools

# Qt5 for MinGW (may require additional repositories)
sudo apt-get install qt5-qmake-bin
# or build Qt5 with MXE: https://mxe.cc/
```

#### Fedora:
```bash
# MinGW-w64 toolchain and Qt5
sudo dnf install mingw64-gcc mingw64-gcc-c++ mingw64-qt5-qtbase-devel mingw64-qt5-qttools
```

#### Arch Linux:
```bash
# MinGW-w64 and Qt5
sudo pacman -S mingw-w64-gcc mingw-w64-qt5-base mingw-w64-qt5-tools
```

#### Using MXE (Cross-platform):
```bash
# Clone and build MXE with Qt5
git clone https://github.com/mxe/mxe.git
cd mxe
make MXE_TARGETS=x86_64-w64-mingw32.shared qt5
```

## Troubleshooting

### Linux Build Issues
- **Qt5 not found**: Install Qt5 development packages for your distribution
- **Missing headers**: Ensure `qtbase5-dev` or equivalent is installed
- **Linker errors**: Try adding `-fPIC` flag or install `qt5-default`

### Windows Cross-Compilation Issues
- **MinGW not found**: Install MinGW-w64 toolchain
- **Qt5 libraries missing**: Install MinGW Qt5 packages or build with MXE
- **DLL dependencies**: The release script automatically copies required DLLs
- **Runtime errors**: Ensure Visual C++ Redistributable is installed on target Windows system

### General Issues
- **Parser files missing**: Run `make menuconfig` in the original project first
- **Permission denied**: Make scripts executable with `chmod +x *.sh`
- **Display issues**: qconf requires X11/Wayland display for GUI

## Notes

- The parser files (zconf.tab.c, zconf.lex.c, zconf.hash.c) must be generated from the original project first by running `make menuconfig` or similar.
- This standalone version includes all necessary kconfig library functions.
- The build system supports both Qt4 and Qt5, but Qt5 is recommended.
- Cross-compilation produces fully portable Windows executables with all dependencies included.

## Files Included

### Core qconf files:
- qconf.cc, qconf.h - Main Qt application
- images.c - Embedded icons and images

### Kconfig library:
- zconf.tab.c - Generated parser that includes all kconfig functionality
- parser_stubs.c - Minimal stub implementations for missing functions

### Headers:
- lkc.h, lkc_proto.h - Main kconfig headers
- expr.h - Expression definitions
- list.h - Linked list implementation

### Individual source files (for reference):
- confdata.c - Configuration data handling
- symbol.c - Symbol management
- menu.c - Menu structure handling
- expr.c - Expression evaluation
- util.c - Utility functions

### Parser source files (for regeneration if needed):
- zconf.y - Parser grammar
- zconf.l - Lexer rules
- zconf.gperf - Hash function generator
