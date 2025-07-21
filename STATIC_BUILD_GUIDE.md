# qconf Static Build Guide

This guide explains how to build qconf with static linking to create standalone executables with minimal external dependencies.

## Overview

Static linking creates executables that include all necessary libraries, making them portable and easier to distribute. The qconf project now supports multiple static build methods across different platforms.

## Build Methods

### 1. Windows Static Builds

#### Method 1: Dedicated Static Build Scripts (Recommended)

**Batch Script:**
```batch
# Full static build with comprehensive library linking
build-windows-static.bat
```

**PowerShell Script:**
```powershell
# Static build with dependency checking
.\build-windows-static.ps1
```

**Features:**
- Automatic Qt5 detection
- Comprehensive static library linking
- Dependency verification
- True static executable (no external DLLs)

#### Method 2: Enhanced Build Scripts with Static Flag

**Batch Script:**
```batch
# Use existing script with static configuration
build-windows-native.bat
```

**PowerShell Script:**
```powershell
# Use enhanced script with static flag
.\build-windows.ps1 -Static
```

#### Method 3: qmake with Static Configuration

**Using dedicated static project file:**
```bash
qmake qconf-windows-static.pro
mingw32-make
```

**Using regular project file with static config:**
```bash
qmake CONFIG+=static qconf-windows-fixed.pro
mingw32-make
```

#### Method 4: CMake Static Build

```bash
mkdir build-static
cd build-static
cmake .. -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

### 2. Linux/Unix Static Builds

#### Method 1: Comprehensive Static Build Script (Recommended)

```bash
# Automatic method detection and static build
./build-all-static.sh

# Specific build method
./build-all-static.sh qmake
./build-all-static.sh cmake
./build-all-static.sh manual

# Clean build
./build-all-static.sh clean
```

#### Method 2: CMake Static Build

```bash
# Using dedicated CMake script
./build-cmake-static.sh

# Manual CMake static build
mkdir build-static
cd build-static
cmake .. -DBUILD_STATIC=ON
make
```

#### Method 3: qmake Static Build

```bash
# If static Qt5 libraries are available
qmake CONFIG+=static qconf-windows-fixed.pro
make
```

## Requirements

### Windows Requirements

1. **Qt5 with MinGW** (with static libraries)
   - Download from: https://www.qt.io/download-qt-installer
   - Ensure static libraries are included in installation
   - Common paths: `C:\Qt\5.15.2\mingw81_64`

2. **MinGW Compiler**
   - Usually included with Qt5 installer
   - Must be in PATH or detected automatically

3. **Build Tools**
   - qmake (included with Qt5)
   - mingw32-make or make
   - moc (Qt5 Meta-Object Compiler)

### Linux Requirements

1. **Qt5 Development Packages**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install qt5-default qtbase5-dev qtbase5-dev-tools
   
   # CentOS/RHEL/Fedora
   sudo yum install qt5-qtbase-devel qt5-qtbase-static
   # or
   sudo dnf install qt5-qtbase-devel qt5-qtbase-static
   ```

2. **Build Tools**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install build-essential cmake
   
   # CentOS/RHEL/Fedora
   sudo yum install gcc gcc-c++ make cmake
   ```

3. **Static Qt5 Libraries** (for true static builds)
   - May need to compile Qt5 from source with static configuration
   - Or install distribution-specific static packages

## Build Outputs

### Executable Names

- **Static builds**: `qconf-static.exe` (Windows) or `qconf-static` (Linux)
- **Dynamic builds**: `qconf.exe` (Windows) or `qconf` (Linux)

### Verification

All build scripts include automatic verification:

1. **Functionality Test**: Runs `--help` to verify the executable works
2. **Dependency Check**: 
   - Windows: Uses `objdump` to check DLL dependencies
   - Linux: Uses `ldd` to check shared library dependencies
3. **Size Report**: Shows executable file size

## Troubleshooting

### Common Issues

1. **Qt5 Not Found**
   - Ensure Qt5 is installed and in PATH
   - For Windows: Check common installation paths
   - For Linux: Install qt5-default or qtbase5-dev packages

2. **Static Libraries Missing**
   - Windows: Ensure Qt5 installation includes static libraries
   - Linux: Install qt5-qtbase-static or compile Qt5 with static support

3. **Compiler Not Found**
   - Windows: Ensure MinGW is installed and in PATH
   - Linux: Install build-essential or gcc/g++ packages

4. **Linking Errors**
   - Check that all required libraries are available
   - For static builds, ensure static versions of libraries exist
   - Review compiler/linker error messages for missing dependencies

### Platform-Specific Notes

#### Windows
- Static builds require Qt5 to be compiled with static support
- Some Qt5 installations may not include static libraries by default
- Use MinGW compiler (not MSVC) for better static linking support

#### Linux
- Static Qt5 libraries may not be available in all distributions
- May need to compile Qt5 from source for full static support
- Some system libraries (like glibc) cannot be statically linked

## Advanced Configuration

### Custom Qt5 Path

**Windows:**
```batch
# Batch script
set QT_DIR=C:\path\to\qt5
build-windows-static.bat

# PowerShell
.\build-windows-static.ps1 -QtPath "C:\path\to\qt5"
```

**Linux:**
```bash
# Set Qt5 path
export PATH="/path/to/qt5/bin:$PATH"
./build-all-static.sh
```

### Build Type Selection

```bash
# Release build (default)
cmake .. -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=Release

# Debug build
cmake .. -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=Debug
```

### Compiler Flags

Static builds include these additional flags:
- `-static`: Link libraries statically
- `-static-libgcc`: Link libgcc statically
- `-static-libstdc++`: Link libstdc++ statically
- `-DSTATIC_BUILD`: Define static build macro
- `-DQT_STATICPLUGIN`: Enable Qt5 static plugins

## Distribution

Static executables can be distributed without:
- Qt5 runtime libraries
- MinGW runtime libraries (Windows)
- Most system libraries (Linux - some exceptions apply)

### Windows Distribution
- Single `.exe` file
- No Qt5 DLLs required
- No MinGW DLLs required
- May still depend on system DLLs (kernel32.dll, user32.dll, etc.)

### Linux Distribution
- Single executable file
- Reduced dependency on system libraries
- May still require basic system libraries (libc, libm, etc.)
- More portable across different Linux distributions

## Performance Considerations

- **Size**: Static executables are larger due to included libraries
- **Memory**: May use more memory due to duplicate library code
- **Startup**: Slightly faster startup (no dynamic library loading)
- **Updates**: Must rebuild to update included libraries

## Examples

### Quick Static Build (Windows)
```batch
# Download and extract qconf_standalone
# Open Command Prompt in qconf_standalone directory
build-windows-static.bat
# Result: qconf-static.exe ready for distribution
```

### Quick Static Build (Linux)
```bash
# Download and extract qconf_standalone
cd qconf_standalone
chmod +x build-all-static.sh
./build-all-static.sh
# Result: qconf-static ready for distribution
```

### Verify Static Build
```bash
# Windows
objdump -p qconf-static.exe | findstr "DLL Name"

# Linux
ldd qconf-static
```

If the static build is successful, you should see minimal or no external dependencies.