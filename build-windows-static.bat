@echo off
REM Windows static build script for qconf
REM This script builds qconf with full static linking (no external DLL dependencies)

setlocal enabledelayedexpansion

echo ========================================
echo qconf Windows Static Build Script
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "qconf.cc" (
    echo Error: qconf.cc not found. Please run this script from the qconf_standalone directory.
    pause
    exit /b 1
)

REM Check for required files
if not exist "zconf.tab.c" (
    echo Error: zconf.tab.c not found. Please run the original build first to generate parser files.
    pause
    exit /b 1
)

REM Detect build environment
set "BUILD_ENV="
set "QT_DIR="
set "QT_VERSION="

REM Check for Qt5 installation
echo Detecting Qt5 installation...

REM Try common Qt5 installation paths
for %%P in (
    "C:\Qt\5.15.2\mingw81_64"
    "C:\Qt\5.15.1\mingw81_64"
    "C:\Qt\5.15.0\mingw81_64"
    "C:\Qt\5.14.2\mingw73_64"
    "C:\Qt\5.12.12\mingw73_64"
    "C:\Qt\Tools\mingw810_64"
    "C:\msys64\mingw64"
    "C:\msys64\ucrt64"
) do (
    if exist "%%~P\bin\qmake.exe" (
        set "QT_DIR=%%~P"
        echo Found Qt5 at: !QT_DIR!
        goto :qt_found
    )
)

REM Try to find Qt5 in PATH
where qmake.exe >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('where qmake.exe') do (
        set "QT_DIR=%%~dpi.."
        echo Found Qt5 in PATH: !QT_DIR!
        goto :qt_found
    )
)

echo Error: Qt5 not found. Please install Qt5 with MinGW or add it to PATH.
echo.
echo Download Qt5 from: https://www.qt.io/download-qt-installer
echo Make sure to install the MinGW version.
pause
exit /b 1

:qt_found
REM Set Qt5 paths
set "QT_BIN=%QT_DIR%\bin"
set "QT_LIB=%QT_DIR%\lib"
set "QT_INCLUDE=%QT_DIR%\include"

REM Add Qt5 to PATH
set "PATH=%QT_BIN%;%PATH%"

REM Check for compiler
echo Checking for C++ compiler...
where g++.exe >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: g++ compiler not found in PATH.
    echo Please ensure MinGW is installed and in PATH.
    pause
    exit /b 1
)

REM Check for moc
where moc.exe >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: moc.exe not found in PATH.
    echo Please ensure Qt5 bin directory is in PATH: %QT_BIN%
    pause
    exit /b 1
)

echo Build environment ready for STATIC BUILD!
echo   Qt5 Directory: %QT_DIR%
echo   Compiler: 
g++ --version | findstr "g++"
echo   MOC: 
moc -v
echo   Static Linking: ENABLED
echo.

REM Clean previous build
echo Cleaning previous build...
if exist "*.o" del /q *.o
if exist "qconf.moc" del /q qconf.moc
if exist "qconf.exe" del /q qconf.exe
if exist "qconf-static.exe" del /q qconf-static.exe
if exist "Makefile" del /q Makefile

REM Try qmake method first (preferred)
if exist "qconf-windows-static.pro" (
    echo Building with qmake using static configuration...
    
    REM Generate Makefile with static configuration
    echo Generating Makefile for static build...
    qmake qconf-windows-static.pro
    if !errorlevel! neq 0 (
        echo Error: qmake failed for static configuration
        goto :manual_build
    )
    
    REM Build using make
    echo Building with make...
    mingw32-make 2>nul
    if !errorlevel! equ 0 (
        echo Static build with qmake completed successfully!
        goto :build_complete
    ) else (
        echo qmake build failed, trying manual build...
        goto :manual_build
    )
) else (
    echo qconf-windows-static.pro not found, using manual build...
    goto :manual_build
)

:manual_build
echo Performing manual static build...

REM Set compiler flags for static build
set "CFLAGS=-O2 -Wall -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-implicit-fallthrough -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_WIN32 -DUNICODE -D_UNICODE -DSTATIC_BUILD"
set "CXXFLAGS=-std=c++11 -O2 -Wall -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-deprecated-declarations -Wno-implicit-fallthrough -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_WIN32 -DUNICODE -D_UNICODE -DSTATIC_BUILD"

REM Add Qt5 include paths
set "QT_INCLUDES=-I%QT_INCLUDE% -I%QT_INCLUDE%\QtCore -I%QT_INCLUDE%\QtGui -I%QT_INCLUDE%\QtWidgets"
set "QT_DEFINES=-DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_STATICPLUGIN"

REM Set Qt5 library flags for static linking
set "QT_LIBS_STATIC=-L%QT_LIB% -static -static-libgcc -static-libstdc++ -lQt5Widgets -lQt5Gui -lQt5Core -lqwindows -lqwindowsvistastyle -lQt5FontDatabaseSupport -lQt5EventDispatcherSupport -lQt5ThemeSupport -lQt5AccessibilitySupport -lqtfreetype -lqtharfbuzz -lqtlibpng -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32 -lwinspool -lcomctl32 -lrpcrt4 -lmsimg32 -lopengl32 -lglu32 -lusp10"

REM Generate MOC file
echo Generating MOC file...
moc -i qconf.h -o qconf.moc
if !errorlevel! neq 0 (
    echo Error: MOC generation failed
    pause
    exit /b 1
)

REM Compile C files
echo Compiling C files...
gcc %CFLAGS% -c zconf.tab.c -o zconf.tab.o
if !errorlevel! neq 0 (
    echo Error: Failed to compile zconf.tab.c
    pause
    exit /b 1
)

gcc %CFLAGS% -c parser_stubs.c -o parser_stubs.o
if !errorlevel! neq 0 (
    echo Error: Failed to compile parser_stubs.c
    pause
    exit /b 1
)

REM Compile C++ files
echo Compiling C++ files...
g++ %CXXFLAGS% %QT_INCLUDES% %QT_DEFINES% -c qconf.cc -o qconf.o
if !errorlevel! neq 0 (
    echo Error: Failed to compile qconf.cc
    pause
    exit /b 1
)

REM Link static executable
echo Linking static executable...
g++ -o qconf-static.exe zconf.tab.o parser_stubs.o qconf.o %QT_LIBS_STATIC%
if !errorlevel! neq 0 (
    echo Error: Static linking failed
    echo.
    echo This might be due to missing Qt5 static libraries. Please check:
    echo 1. Qt5 static libraries are in: %QT_LIB%
    echo 2. Qt5 was built with static support
    echo 3. The following files exist:
    echo    - %QT_LIB%\libQt5Core.a
    echo    - %QT_LIB%\libQt5Gui.a  
    echo    - %QT_LIB%\libQt5Widgets.a
    echo    - %QT_LIB%\libqwindows.a
    pause
    exit /b 1
)

:build_complete
REM Check if executable was created
set "EXECUTABLE=qconf-static.exe"
if exist "qconf-static.exe" (
    set "EXECUTABLE=qconf-static.exe"
) else if exist "qconf.exe" (
    set "EXECUTABLE=qconf.exe"
) else (
    echo Error: No executable was created
    pause
    exit /b 1
)

echo.
echo ========================================
echo Static Build completed successfully!
echo ========================================
echo.
echo Created: %EXECUTABLE%
echo Size: 
for %%F in (%EXECUTABLE%) do echo   %%~zF bytes

REM Test the executable
echo.
echo Testing static executable...
%EXECUTABLE% --help >nul 2>&1
if !errorlevel! equ 0 (
    echo.
    echo SUCCESS: %EXECUTABLE% is working correctly!
    echo.
    echo This is a STATIC executable with no external DLL dependencies.
    echo You can distribute this file without Qt5 runtime libraries.
    echo.
    echo Usage: %EXECUTABLE% ^<Kconfig-file^>
    echo Test:  %EXECUTABLE% test_Kconfig
) else (
    echo.
    echo WARNING: %EXECUTABLE% may have issues. Try running it manually.
)

REM Check dependencies (optional)
echo.
echo Checking dependencies...
where objdump.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo Dynamic library dependencies:
    objdump -p %EXECUTABLE% | findstr "DLL Name"
    if !errorlevel! neq 0 (
        echo   No external DLL dependencies found - TRUE STATIC BUILD!
    )
) else (
    echo objdump not found - cannot check dependencies
)

echo.
echo Static build log saved to build-static.log
pause