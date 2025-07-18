#!/bin/bash
# Windows release packaging script for qconf

set -e

VERSION=${VERSION:-$(date +%Y%m%d)}
RELEASE_NAME="qconf-windows-x64-${VERSION}"
RELEASE_DIR="releases/${RELEASE_NAME}"

echo "Creating Windows release package..."

# Check if we have the Windows executable
if [ ! -f "qconf.exe" ]; then
    echo "Error: qconf.exe not found. Run 'make win64' first."
    exit 1
fi

# Create release directory
mkdir -p "${RELEASE_DIR}"

# Copy executable (prefer stripped version)
if [ -f "qconf-stripped.exe" ]; then
    cp qconf-stripped.exe "${RELEASE_DIR}/qconf.exe"
else
    cp qconf.exe "${RELEASE_DIR}/qconf.exe"
fi

# Copy documentation
cp README.md "${RELEASE_DIR}/"
cp test_Kconfig "${RELEASE_DIR}/"

# Create batch file for easy execution
cat > "${RELEASE_DIR}/qconf.bat" << 'EOF'
@echo off
REM qconf launcher batch file

if "%1"=="" (
    echo Usage: qconf.bat ^<Kconfig-file^>
    echo Example: qconf.bat test_Kconfig
    pause
    exit /b 1
)

REM Check if file exists
if not exist "%1" (
    echo Error: File "%1" not found
    pause
    exit /b 1
)

REM Launch qconf
"%~dp0qconf.exe" "%1"
EOF

# Create PowerShell script for advanced users
cat > "${RELEASE_DIR}/qconf.ps1" << 'EOF'
# qconf PowerShell launcher
param(
    [Parameter(Mandatory=$true)]
    [string]$KconfigFile
)

if (-not (Test-Path $KconfigFile)) {
    Write-Error "File not found: $KconfigFile"
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$qconfExe = Join-Path $scriptDir "qconf.exe"

if (-not (Test-Path $qconfExe)) {
    Write-Error "qconf.exe not found in $scriptDir"
    exit 1
}

& $qconfExe $KconfigFile
EOF

# Create usage instructions
cat > "${RELEASE_DIR}/USAGE.txt" << 'EOF'
qconf - Qt-based Kconfig Configuration Tool for Windows
=======================================================

INSTALLATION:
  1. Extract this archive to any directory (e.g., C:\Tools\qconf)
  2. Optionally add the directory to your PATH environment variable

USAGE:
  Method 1 - Command Line:
    qconf.exe <Kconfig-file>
    
  Method 2 - Batch File:
    qconf.bat <Kconfig-file>
    
  Method 3 - PowerShell:
    .\qconf.ps1 <Kconfig-file>
    
  Examples:
    qconf.exe test_Kconfig          # Test with included sample
    qconf.bat test_Kconfig          # Same using batch file
    qconf.exe C:\project\Kconfig    # Use with your project

REQUIREMENTS:
  - Windows 7 or later (x64)
  - All required Qt5 DLLs are included in this package

TROUBLESHOOTING:
  If you get "MSVCP140.dll missing" or similar errors:
    - Install Microsoft Visual C++ Redistributable for Visual Studio 2015-2019
    - Download from: https://aka.ms/vs/16/release/vc_redist.x64.exe
    
  If the GUI doesn't appear:
    - Make sure you're running from a desktop environment (not SSH/remote)
    - Try running from Command Prompt or PowerShell
    
  If you get "Qt platform plugin" errors:
    - Make sure all DLL files are in the same directory as qconf.exe
    - Don't separate the executable from the DLL files
EOF

# Function to find and copy DLL dependencies
copy_dll_deps() {
    local exe_file="$1"
    local target_dir="$2"
    
    echo "Finding DLL dependencies for $exe_file..."
    
    # Try to find MinGW Qt5 installation
    local qt5_bin_dirs=(
        "/usr/x86_64-w64-mingw32/bin"
        "/usr/lib/mxe/usr/x86_64-w64-mingw32.shared/bin"
        "/usr/lib/mxe/usr/x86_64-w64-mingw32.static/bin"
        $(find /usr -name "*mingw*qt5*bin" -type d 2>/dev/null)
        $(find /usr -path "*mingw*" -name "Qt5*.dll" -exec dirname {} \; 2>/dev/null | sort -u)
    )
    
    # Find Qt5 DLLs
    local qt5_dlls=("Qt5Core.dll" "Qt5Gui.dll" "Qt5Widgets.dll")
    local found_qt5=false
    
    for bin_dir in "${qt5_bin_dirs[@]}"; do
        if [ -d "$bin_dir" ]; then
            echo "Checking Qt5 directory: $bin_dir"
            local all_found=true
            for dll in "${qt5_dlls[@]}"; do
                if [ ! -f "$bin_dir/$dll" ]; then
                    all_found=false
                    break
                fi
            done
            
            if [ "$all_found" = true ]; then
                echo "Found Qt5 DLLs in: $bin_dir"
                for dll in "${qt5_dlls[@]}"; do
                    cp "$bin_dir/$dll" "$target_dir/"
                    echo "  Copied: $dll"
                done
                
                # Copy Qt5 platform plugins
                local platforms_src="$bin_dir/../share/qt5/plugins/platforms"
                if [ ! -d "$platforms_src" ]; then
                    platforms_src="$bin_dir/../lib/qt5/plugins/platforms"
                fi
                if [ ! -d "$platforms_src" ]; then
                    platforms_src="$(dirname "$bin_dir")/plugins/platforms"
                fi
                
                if [ -d "$platforms_src" ]; then
                    mkdir -p "$target_dir/platforms"
                    cp "$platforms_src/qwindows.dll" "$target_dir/platforms/" 2>/dev/null || echo "  Warning: qwindows.dll not found"
                    echo "  Copied: platforms/qwindows.dll"
                fi
                
                found_qt5=true
                break
            fi
        fi
    done
    
    if [ "$found_qt5" = false ]; then
        echo "Warning: Could not find Qt5 DLLs automatically."
        echo "You may need to manually copy the following DLLs to the release directory:"
        echo "  - Qt5Core.dll"
        echo "  - Qt5Gui.dll" 
        echo "  - Qt5Widgets.dll"
        echo "  - platforms/qwindows.dll"
        return 1
    fi
    
    # Find and copy MinGW runtime DLLs
    local mingw_bin="/usr/lib/gcc/x86_64-w64-mingw32"
    if [ -d "$mingw_bin" ]; then
        # Find the latest GCC version
        local gcc_version=$(ls "$mingw_bin" | sort -V | tail -1)
        local gcc_bin="$mingw_bin/$gcc_version"
        
        if [ -d "$gcc_bin" ]; then
            echo "Found MinGW GCC runtime in: $gcc_bin"
            local runtime_dlls=("libgcc_s_seh-1.dll" "libstdc++-6.dll" "libwinpthread-1.dll")
            
            for dll in "${runtime_dlls[@]}"; do
                if [ -f "$gcc_bin/$dll" ]; then
                    cp "$gcc_bin/$dll" "$target_dir/"
                    echo "  Copied: $dll"
                elif [ -f "/usr/x86_64-w64-mingw32/lib/$dll" ]; then
                    cp "/usr/x86_64-w64-mingw32/lib/$dll" "$target_dir/"
                    echo "  Copied: $dll"
                fi
            done
        fi
    fi
    
    return 0
}

# Copy DLL dependencies
echo "Copying Windows DLL dependencies..."
if copy_dll_deps "qconf.exe" "${RELEASE_DIR}"; then
    echo "DLL dependencies copied successfully."
else
    echo "Warning: Some DLL dependencies may be missing."
fi

# Create a simple dependency checker script
cat > "${RELEASE_DIR}/check-deps.bat" << 'EOF'
@echo off
echo Checking qconf dependencies...
echo.

REM Check if main executable exists
if not exist "qconf.exe" (
    echo ERROR: qconf.exe not found!
    goto :error
)

REM Check Qt5 DLLs
set "missing_dlls="
for %%d in (Qt5Core.dll Qt5Gui.dll Qt5Widgets.dll) do (
    if not exist "%%d" (
        set "missing_dlls=!missing_dlls! %%d"
    )
)

if defined missing_dlls (
    echo ERROR: Missing Qt5 DLLs: %missing_dlls%
    goto :error
)

REM Check platform plugin
if not exist "platforms\qwindows.dll" (
    echo ERROR: Missing platforms\qwindows.dll
    goto :error
)

echo SUCCESS: All dependencies found!
echo You can now run qconf.exe
goto :end

:error
echo.
echo Please ensure all DLL files are present in this directory.
echo If you're missing DLLs, you may need to install:
echo - Microsoft Visual C++ Redistributable
echo - Or copy DLLs from a MinGW Qt5 installation

:end
pause
EOF

# List all files in the release
echo "Windows release contents:"
find "${RELEASE_DIR}" -type f -exec ls -la {} \;

# Create zip archive
cd releases
if command -v zip >/dev/null 2>&1; then
    zip -r "${RELEASE_NAME}.zip" "${RELEASE_NAME}"
    echo "Windows release created: releases/${RELEASE_NAME}.zip"
else
    echo "Warning: 'zip' command not found. Creating tar.gz instead."
    tar -czf "${RELEASE_NAME}.tar.gz" "${RELEASE_NAME}"
    echo "Windows release created: releases/${RELEASE_NAME}.tar.gz"
fi
cd ..

echo "Windows release packaging complete!"
echo "Release directory: ${RELEASE_DIR}"