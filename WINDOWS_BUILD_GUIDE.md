# Windows Build Guide for qconf

This guide helps you build qconf natively on Windows, addressing common issues like the "ld returned 5 exit status" error.

## Quick Solutions for Common Errors

### Error: "ld returned 5 exit status"
This is typically caused by missing Qt5 libraries or incorrect library paths. Here are the solutions:

#### Solution 1: Use the Automated Build Scripts (Recommended)
```cmd
# Try the enhanced batch script
build-windows-native.bat

# Or use PowerShell (more robust)
.\build-windows.ps1

# Or use the simple qmake approach
build_windows.bat
```

#### Solution 2: Manual qmake Build (Most Reliable)
```cmd
# 1. Make sure Qt5 is in PATH
where qmake
where moc

# 2. Use the provided project file
qmake qconf-windows.pro

# 3. Build with appropriate make tool
mingw32-make
# OR
make
# OR (for MSVC)
nmake
```

#### Solution 3: Fix Library Paths Manually
If you're still getting linking errors, the issue is likely missing Qt5 libraries:

```cmd
# Check if Qt5 libraries exist
dir "C:\Qt\5.15.2\mingw81_64\lib\libQt5*.a"

# If not found, locate your Qt5 installation
where qmake
# This will show you the Qt5 bin directory
# The lib directory should be at the same level
```

## Prerequisites

### 1. Install Qt5 with MinGW
Download from: https://www.qt.io/download-qt-installer

**Important**: Make sure to select:
- Qt 5.15.x (or latest 5.x version)
- MinGW 8.1.0 64-bit (or latest MinGW)
- Qt Creator (optional but helpful)

### 2. Add Qt5 to PATH
Add these directories to your Windows PATH:
```
C:\Qt\5.15.2\mingw81_64\bin
C:\Qt\Tools\mingw810_64\bin
```

### 3. Verify Installation
```cmd
# Check Qt5
qmake -v
moc -v

# Check compiler
gcc --version
g++ --version

# Check make tool
mingw32-make --version
```

## Build Methods

### Method 1: Automated Build Script (Easiest)
```cmd
# Enhanced batch script with automatic Qt5 detection
build-windows-native.bat

# This script will:
# - Automatically find Qt5 installation
# - Set up environment variables
# - Compile and link everything
# - Test the executable
```

### Method 2: PowerShell Script (Most Robust)
```powershell
# PowerShell script with advanced error handling
.\build-windows.ps1

# With custom Qt5 path
.\build-windows.ps1 -QtPath "C:\Qt\5.15.2\mingw81_64"

# Clean build
.\build-windows.ps1 -Clean
```

### Method 3: qmake Project File (Recommended for Developers)
```cmd
# Use the provided project file
qmake qconf-windows.pro

# Build
mingw32-make
```

### Method 4: Manual Build (For Troubleshooting)
```cmd
# Set environment (adjust paths as needed)
set QT_DIR=C:\Qt\5.15.2\mingw81_64
set PATH=%QT_DIR%\bin;%PATH%

# Generate MOC file
moc -i qconf.h -o qconf.moc

# Compile C files
gcc -O2 -Wall -DPACKAGE="qconf" -DKBUILD_NO_NLS -D_WIN32 -c zconf.tab.c -o zconf.tab.o
gcc -O2 -Wall -DPACKAGE="qconf" -DKBUILD_NO_NLS -D_WIN32 -c parser_stubs.c -o parser_stubs.o

# Compile C++ file
g++ -std=c++11 -O2 -Wall -DPACKAGE="qconf" -DKBUILD_NO_NLS -D_WIN32 ^
    -I%QT_DIR%\include -I%QT_DIR%\include\QtCore -I%QT_DIR%\include\QtGui -I%QT_DIR%\include\QtWidgets ^
    -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB ^
    -c qconf.cc -o qconf.o

# Link executable
g++ -o qconf.exe zconf.tab.o parser_stubs.o qconf.o ^
    -L%QT_DIR%\lib -lQt5Widgets -lQt5Gui -lQt5Core ^
    -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32
```

## Troubleshooting Specific Errors

### "Qt5Core.dll not found" or similar DLL errors
```cmd
# Copy Qt5 DLLs to the same directory as qconf.exe
copy "%QT_DIR%\bin\Qt5Core.dll" .
copy "%QT_DIR%\bin\Qt5Gui.dll" .
copy "%QT_DIR%\bin\Qt5Widgets.dll" .

# Copy platform plugins
mkdir platforms
copy "%QT_DIR%\plugins\platforms\qwindows.dll" platforms\
```

### "moc: command not found"
```cmd
# Add Qt5 bin directory to PATH
set PATH=C:\Qt\5.15.2\mingw81_64\bin;%PATH%

# Or use full path
C:\Qt\5.15.2\mingw81_64\bin\moc -i qconf.h -o qconf.moc
```

### "gcc: command not found"
```cmd
# Add MinGW bin directory to PATH
set PATH=C:\Qt\Tools\mingw810_64\bin;%PATH%

# Or install MinGW separately from: https://www.mingw-w64.org/
```

### "cannot find -lQt5Widgets" or similar library errors
This means the linker can't find Qt5 libraries. Solutions:

1. **Check library directory exists:**
   ```cmd
   dir "C:\Qt\5.15.2\mingw81_64\lib\libQt5*.a"
   ```

2. **Use correct library path:**
   ```cmd
   # Make sure -L points to the correct lib directory
   g++ ... -L"C:\Qt\5.15.2\mingw81_64\lib" -lQt5Widgets -lQt5Gui -lQt5Core ...
   ```

3. **Check Qt5 installation:**
   - Reinstall Qt5 with MinGW components
   - Make sure you selected the correct architecture (64-bit)

### "undefined reference to" errors
This usually means missing system libraries:

```cmd
# Make sure you include all Windows libraries
g++ ... -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32
```

## Environment Setup

### Option 1: Qt Creator Command Prompt
If you installed Qt Creator, use "Qt 5.15.2 (MinGW 8.1.0 64-bit)" command prompt from Start Menu.

### Option 2: Manual Environment Setup
Create a batch file `setup-qt-env.bat`:
```cmd
@echo off
set QT_DIR=C:\Qt\5.15.2\mingw81_64
set MINGW_DIR=C:\Qt\Tools\mingw810_64
set PATH=%QT_DIR%\bin;%MINGW_DIR%\bin;%PATH%
echo Qt5 environment ready!
cmd
```

## Testing the Build

### Basic Test
```cmd
# Test help output
qconf.exe --help

# Test with sample config
qconf.exe test_Kconfig
```

### Dependency Check
```cmd
# Check DLL dependencies (if you have Dependency Walker)
depends.exe qconf.exe

# Or use PowerShell
Get-Command qconf.exe | Select-Object -ExpandProperty FileVersionInfo
```

## Alternative: Using MSYS2

If you prefer MSYS2 environment:

```bash
# Install MSYS2 from https://www.msys2.org/
# Then install packages:
pacman -S mingw-w64-x86_64-gcc
pacman -S mingw-w64-x86_64-qt5-base
pacman -S mingw-w64-x86_64-qt5-tools

# Build normally
make win64
```

## Common Qt5 Installation Paths

Check these locations for your Qt5 installation:
- `C:\Qt\5.15.2\mingw81_64\`
- `C:\Qt\5.15.1\mingw81_64\`
- `C:\Qt\5.14.2\mingw73_64\`
- `C:\Qt\5.12.12\mingw73_64\`
- `C:\msys64\mingw64\` (MSYS2)
- `C:\msys64\ucrt64\` (MSYS2 UCRT)

## Success Indicators

When the build succeeds, you should see:
1. `qconf.exe` created (typically 200-500 KB)
2. No error messages during linking
3. `qconf.exe --help` shows usage information
4. `qconf.exe test_Kconfig` opens the GUI (if display available)

## Getting Help

If you're still having issues:

1. **Check the build log** - Look for the exact error message
2. **Verify Qt5 installation** - Make sure all components are installed
3. **Try different build methods** - qmake is usually most reliable
4. **Use the automated scripts** - They handle most common issues
5. **Check PATH environment** - Make sure Qt5 and MinGW are in PATH

The automated build scripts (`build-windows-native.bat` and `build-windows.ps1`) are designed to handle most of these issues automatically and provide detailed error messages to help diagnose problems.