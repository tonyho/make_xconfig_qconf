@echo off
REM Native Windows build script for qconf
REM This script builds qconf directly on Windows using MinGW or MSVC

setlocal enabledelayedexpansion

echo ========================================
echo qconf Windows Native Build Script
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
echo.
echo Common installation paths:
echo   C:\Qt\5.15.2\mingw81_64
echo   C:\msys64\mingw64
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
    echo.
    echo If using Qt5 installer, the compiler should be at:
    echo   %QT_DIR%\..\..\Tools\mingw810_64\bin
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

echo Build environment ready!
echo   Qt5 Directory: %QT_DIR%
echo   Compiler: 
g++ --version | findstr "g++"
echo   MOC: 
moc -v
echo.

REM Set compiler flags (with warning suppressions for Windows compatibility)
set "CFLAGS=-O2 -Wall -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_WIN32 -DUNICODE -D_UNICODE"
set "CXXFLAGS=-std=c++11 -O2 -Wall -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-deprecated-declarations -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_WIN32 -DUNICODE -D_UNICODE"

REM Add Qt5 include paths
set "QT_INCLUDES=-I%QT_INCLUDE% -I%QT_INCLUDE%\QtCore -I%QT_INCLUDE%\QtGui -I%QT_INCLUDE%\QtWidgets"
set "QT_DEFINES=-DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB"

REM Set Qt5 library flags
set "QT_LIBS=-L%QT_LIB% -lQt5Widgets -lQt5Gui -lQt5Core -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32"

REM Clean previous build
echo Cleaning previous build...
if exist "*.o" del /q *.o
if exist "qconf.moc" del /q qconf.moc
if exist "qconf.exe" del /q qconf.exe

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

REM Link executable
echo Linking executable...
g++ -o qconf.exe zconf.tab.o parser_stubs.o qconf.o %QT_LIBS%
if !errorlevel! neq 0 (
    echo Error: Linking failed
    echo.
    echo This might be due to missing Qt5 libraries. Please check:
    echo 1. Qt5 libraries are in: %QT_LIB%
    echo 2. The following files exist:
    echo    - %QT_LIB%\libQt5Core.a
    echo    - %QT_LIB%\libQt5Gui.a  
    echo    - %QT_LIB%\libQt5Widgets.a
    pause
    exit /b 1
)

REM Check if executable was created
if not exist "qconf.exe" (
    echo Error: qconf.exe was not created
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Created: qconf.exe
echo Size: 
for %%F in (qconf.exe) do echo   %%~zF bytes

REM Test the executable
echo.
echo Testing executable...
qconf.exe --help
if !errorlevel! equ 0 (
    echo.
    echo SUCCESS: qconf.exe is working correctly!
    echo.
    echo Usage: qconf.exe ^<Kconfig-file^>
    echo Test:  qconf.exe test_Kconfig
) else (
    echo.
    echo WARNING: qconf.exe may have issues. Try running it manually.
)

echo.
echo Build log saved to build.log
pause