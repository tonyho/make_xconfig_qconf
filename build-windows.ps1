# PowerShell build script for qconf on Windows
# Usage: .\build-windows.ps1

param(
    [switch]$Clean,
    [switch]$Verbose,
    [string]$QtPath = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "qconf Windows Build Script (PowerShell)" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to find Qt5 installation
function Find-Qt5Installation {
    $qtPaths = @(
        "C:\Qt\5.15.2\mingw81_64",
        "C:\Qt\5.15.1\mingw81_64", 
        "C:\Qt\5.15.0\mingw81_64",
        "C:\Qt\5.14.2\mingw73_64",
        "C:\Qt\5.12.12\mingw73_64",
        "C:\msys64\mingw64",
        "C:\msys64\ucrt64"
    )
    
    foreach ($path in $qtPaths) {
        if (Test-Path "$path\bin\qmake.exe") {
            return $path
        }
    }
    
    # Try to find in PATH
    $qmakePath = Get-Command qmake.exe -ErrorAction SilentlyContinue
    if ($qmakePath) {
        return Split-Path (Split-Path $qmakePath.Source -Parent) -Parent
    }
    
    return $null
}

# Clean build if requested
if ($Clean) {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
    Remove-Item -Path "*.o", "*.exe", "qconf.moc", "build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Clean completed." -ForegroundColor Green
    if (-not $PSBoundParameters.ContainsKey('QtPath')) {
        exit 0
    }
}

# Check for required files
if (-not (Test-Path "qconf.cc")) {
    Write-Host "Error: qconf.cc not found. Please run this script from the qconf_standalone directory." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "zconf.tab.c")) {
    Write-Host "Error: zconf.tab.c not found. Please run the original build first to generate parser files." -ForegroundColor Red
    exit 1
}

# Find Qt5 installation
if ($QtPath -eq "") {
    Write-Host "Detecting Qt5 installation..." -ForegroundColor Yellow
    $QtPath = Find-Qt5Installation
}

if (-not $QtPath -or -not (Test-Path "$QtPath\bin\qmake.exe")) {
    Write-Host "Error: Qt5 not found. Please install Qt5 with MinGW or specify path with -QtPath parameter." -ForegroundColor Red
    Write-Host ""
    Write-Host "Download Qt5 from: https://www.qt.io/download-qt-installer" -ForegroundColor Cyan
    Write-Host "Make sure to install the MinGW version." -ForegroundColor Cyan
    exit 1
}

Write-Host "Found Qt5 at: $QtPath" -ForegroundColor Green

# Set environment
$env:PATH = "$QtPath\bin;$env:PATH"
$qtBin = "$QtPath\bin"
$qtLib = "$QtPath\lib" 
$qtInclude = "$QtPath\include"

# Check for compiler
$gccPath = Get-Command gcc.exe -ErrorAction SilentlyContinue
if (-not $gccPath) {
    Write-Host "Error: gcc compiler not found in PATH." -ForegroundColor Red
    Write-Host "Please ensure MinGW is installed and in PATH." -ForegroundColor Red
    exit 1
}

# Check for moc
$mocPath = Get-Command moc.exe -ErrorAction SilentlyContinue
if (-not $mocPath) {
    Write-Host "Error: moc.exe not found in PATH." -ForegroundColor Red
    Write-Host "Please ensure Qt5 bin directory is in PATH: $qtBin" -ForegroundColor Red
    exit 1
}

Write-Host "Build environment ready!" -ForegroundColor Green
Write-Host "  Qt5 Directory: $QtPath" -ForegroundColor White
Write-Host "  Compiler: $(gcc --version | Select-String 'gcc')" -ForegroundColor White
Write-Host "  MOC: $(moc -v 2>&1 | Select-String 'moc')" -ForegroundColor White
Write-Host ""

# Build using qmake (recommended method)
if (Test-Path "qconf-windows.pro") {
    Write-Host "Building with qmake (recommended)..." -ForegroundColor Yellow
    
    # Generate Makefile
    Write-Host "Generating Makefile..." -ForegroundColor White
    & qmake qconf-windows.pro
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: qmake failed" -ForegroundColor Red
        exit 1
    }
    
    # Build
    Write-Host "Building..." -ForegroundColor White
    $makeCommand = Get-Command mingw32-make.exe -ErrorAction SilentlyContinue
    if (-not $makeCommand) {
        $makeCommand = Get-Command make.exe -ErrorAction SilentlyContinue
    }
    
    if ($makeCommand) {
        & $makeCommand.Source
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Build failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Error: Neither mingw32-make nor make found" -ForegroundColor Red
        exit 1
    }
} else {
    # Manual build method
    Write-Host "Building manually..." -ForegroundColor Yellow
    
    # Set compiler flags
    $cflags = "-O2", "-Wall", "-DPACKAGE=`"qconf`"", "-DLOCALEDIR=`"/usr/share/locale`"", "-DKBUILD_NO_NLS", "-D_WIN32", "-DUNICODE", "-D_UNICODE"
    $cxxflags = $cflags + @("-std=c++11")
    $qtIncludes = "-I$qtInclude", "-I$qtInclude\QtCore", "-I$qtInclude\QtGui", "-I$qtInclude\QtWidgets"
    $qtDefines = "-DQT_WIDGETS_LIB", "-DQT_GUI_LIB", "-DQT_CORE_LIB"
    $qtLibs = "-L$qtLib", "-lQt5Widgets", "-lQt5Gui", "-lQt5Core", "-lws2_32", "-lole32", "-loleaut32", "-luuid", "-lwinmm", "-lgdi32", "-lcomdlg32", "-limm32", "-lshell32", "-lkernel32", "-luser32", "-ladvapi32"
    
    # Generate MOC file
    Write-Host "Generating MOC file..." -ForegroundColor White
    & moc -i qconf.h -o qconf.moc
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: MOC generation failed" -ForegroundColor Red
        exit 1
    }
    
    # Compile C files
    Write-Host "Compiling C files..." -ForegroundColor White
    & gcc @cflags -c zconf.tab.c -o zconf.tab.o
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to compile zconf.tab.c" -ForegroundColor Red
        exit 1
    }
    
    & gcc @cflags -c parser_stubs.c -o parser_stubs.o
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to compile parser_stubs.c" -ForegroundColor Red
        exit 1
    }
    
    # Compile C++ files
    Write-Host "Compiling C++ files..." -ForegroundColor White
    & g++ @cxxflags @qtIncludes @qtDefines -c qconf.cc -o qconf.o
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to compile qconf.cc" -ForegroundColor Red
        exit 1
    }
    
    # Link executable
    Write-Host "Linking executable..." -ForegroundColor White
    & g++ -o qconf.exe zconf.tab.o parser_stubs.o qconf.o @qtLibs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Linking failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "This might be due to missing Qt5 libraries. Please check:" -ForegroundColor Yellow
        Write-Host "1. Qt5 libraries are in: $qtLib" -ForegroundColor Yellow
        Write-Host "2. The following files exist:" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libQt5Core.a" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libQt5Gui.a" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libQt5Widgets.a" -ForegroundColor Yellow
        exit 1
    }
}

# Check if executable was created
if (-not (Test-Path "qconf.exe")) {
    Write-Host "Error: qconf.exe was not created" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item "qconf.exe").Length
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created: qconf.exe" -ForegroundColor White
Write-Host "Size: $fileSize bytes" -ForegroundColor White

# Test the executable
Write-Host ""
Write-Host "Testing executable..." -ForegroundColor Yellow
try {
    $output = & .\qconf.exe --help 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS: qconf.exe is working correctly!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Usage: qconf.exe <Kconfig-file>" -ForegroundColor Cyan
        Write-Host "Test:  qconf.exe test_Kconfig" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "WARNING: qconf.exe may have issues. Try running it manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "WARNING: Could not test qconf.exe. Try running it manually." -ForegroundColor Yellow
}

Write-Host ""