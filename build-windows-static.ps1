# PowerShell static build script for qconf on Windows
# Usage: .\build-windows-static.ps1

param(
    [switch]$Clean,
    [switch]$Verbose,
    [string]$QtPath = "",
    [string]$BuildType = "Release"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "qconf Windows Static Build Script" -ForegroundColor Cyan  
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
    Remove-Item -Path "*.o", "*.exe", "qconf.moc", "build", "Makefile*" -Recurse -Force -ErrorAction SilentlyContinue
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
    Write-Host "Make sure to install the MinGW version with static libraries." -ForegroundColor Cyan
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

Write-Host "Build environment ready for STATIC BUILD!" -ForegroundColor Green
Write-Host "  Qt5 Directory: $QtPath" -ForegroundColor White
Write-Host "  Compiler: $(gcc --version | Select-String 'gcc')" -ForegroundColor White
Write-Host "  MOC: $(moc -v 2>&1 | Select-String 'moc')" -ForegroundColor White
Write-Host "  Build Type: $BuildType" -ForegroundColor White
Write-Host "  Static Linking: ENABLED" -ForegroundColor Yellow
Write-Host ""

# Try qmake method first (preferred)
$projectFile = "qconf-windows-static.pro"
if (Test-Path $projectFile) {
    Write-Host "Building with qmake using static configuration..." -ForegroundColor Yellow
    
    # Generate Makefile
    Write-Host "Generating Makefile for static build..." -ForegroundColor White
    & qmake $projectFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: qmake failed for static configuration" -ForegroundColor Red
        Write-Host "Falling back to manual build..." -ForegroundColor Yellow
    } else {
        # Build
        Write-Host "Building with make..." -ForegroundColor White
        $makeCommand = Get-Command mingw32-make.exe -ErrorAction SilentlyContinue
        if (-not $makeCommand) {
            $makeCommand = Get-Command make.exe -ErrorAction SilentlyContinue
        }
        
        if ($makeCommand) {
            & $makeCommand.Source
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Static build with qmake completed successfully!" -ForegroundColor Green
                $buildSuccess = $true
            } else {
                Write-Host "qmake build failed, trying manual build..." -ForegroundColor Yellow
                $buildSuccess = $false
            }
        } else {
            Write-Host "Error: Neither mingw32-make nor make found" -ForegroundColor Red
            Write-Host "Trying manual build..." -ForegroundColor Yellow
            $buildSuccess = $false
        }
    }
} else {
    Write-Host "$projectFile not found, using manual build..." -ForegroundColor Yellow
    $buildSuccess = $false
}

# Manual build method if qmake failed
if (-not $buildSuccess) {
    Write-Host "Performing manual static build..." -ForegroundColor Yellow
    
    # Set compiler flags for static build
    $cflags = "-O2", "-Wall", "-Wno-sign-compare", "-Wno-unused-parameter", "-Wno-missing-field-initializers", "-Wno-implicit-fallthrough", "-DPACKAGE=`"qconf`"", "-DLOCALEDIR=`"/usr/share/locale`"", "-DKBUILD_NO_NLS", "-D_WIN32", "-DUNICODE", "-D_UNICODE", "-DSTATIC_BUILD"
    $cxxflags = $cflags + @("-std=c++11")
    $qtIncludes = "-I$qtInclude", "-I$qtInclude\QtCore", "-I$qtInclude\QtGui", "-I$qtInclude\QtWidgets"
    $qtDefines = "-DQT_WIDGETS_LIB", "-DQT_GUI_LIB", "-DQT_CORE_LIB", "-DQT_STATICPLUGIN"
    
    # Static Qt libraries (comprehensive list)
    $qtLibsStatic = @(
        "-L$qtLib",
        "-static", "-static-libgcc", "-static-libstdc++",
        "-lQt5Widgets", "-lQt5Gui", "-lQt5Core",
        "-lqwindows", "-lqwindowsvistastyle",
        "-lQt5FontDatabaseSupport", "-lQt5EventDispatcherSupport", "-lQt5ThemeSupport", "-lQt5AccessibilitySupport",
        "-lqtfreetype", "-lqtharfbuzz", "-lqtlibpng",
        "-lws2_32", "-lole32", "-loleaut32", "-luuid", "-lwinmm", "-lgdi32", "-lcomdlg32", "-limm32", "-lshell32", "-lkernel32", "-luser32", "-ladvapi32",
        "-lwinspool", "-lcomctl32", "-lrpcrt4", "-lmsimg32", "-lopengl32", "-lglu32", "-lusp10"
    )
    
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
    
    # Link static executable
    Write-Host "Linking static executable..." -ForegroundColor White
    & g++ -o qconf-static.exe zconf.tab.o parser_stubs.o qconf.o @qtLibsStatic
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Static linking failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "This might be due to missing Qt5 static libraries. Please check:" -ForegroundColor Yellow
        Write-Host "1. Qt5 static libraries are in: $qtLib" -ForegroundColor Yellow
        Write-Host "2. Qt5 was built with static support" -ForegroundColor Yellow
        Write-Host "3. The following files exist:" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libQt5Core.a" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libQt5Gui.a" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libQt5Widgets.a" -ForegroundColor Yellow
        Write-Host "   - $qtLib\libqwindows.a" -ForegroundColor Yellow
        exit 1
    }
}

# Check if executable was created
$executable = ""
if (Test-Path "qconf-static.exe") {
    $executable = "qconf-static.exe"
} elseif (Test-Path "qconf.exe") {
    $executable = "qconf.exe"
} else {
    Write-Host "Error: No executable was created" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $executable).Length
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Static Build completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created: $executable" -ForegroundColor White
Write-Host "Size: $fileSize bytes" -ForegroundColor White

# Test the executable
Write-Host ""
Write-Host "Testing static executable..." -ForegroundColor Yellow
try {
    $output = & ".\$executable" --help 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS: $executable is working correctly!" -ForegroundColor Green
        Write-Host ""
        Write-Host "This is a STATIC executable with no external DLL dependencies." -ForegroundColor Cyan
        Write-Host "You can distribute this file without Qt5 runtime libraries." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: $executable <Kconfig-file>" -ForegroundColor Cyan
        Write-Host "Test:  $executable test_Kconfig" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "WARNING: $executable may have issues. Try running it manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "WARNING: Could not test $executable. Try running it manually." -ForegroundColor Yellow
}

# Check dependencies (optional)
Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Yellow
$objdumpPath = Get-Command objdump.exe -ErrorAction SilentlyContinue
if ($objdumpPath) {
    Write-Host "Dynamic library dependencies:" -ForegroundColor White
    $deps = & objdump -p $executable | Select-String "DLL Name"
    if ($deps) {
        $deps | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  No external DLL dependencies found - TRUE STATIC BUILD!" -ForegroundColor Green
    }
} else {
    Write-Host "objdump not found - cannot check dependencies" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Static build completed!" -ForegroundColor Green