@echo off
REM Simple Windows build script for qconf
REM This is a simplified version - use build-windows-native.bat for full features

echo Building qconf for Windows...

REM Check if Qt5 is available
where qmake >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Qt5 not found in PATH. Please install Qt5 and add it to PATH.
    echo.
    echo For detailed build instructions, use: build-windows-native.bat
    echo Or try PowerShell version: .\build-windows.ps1
    pause
    exit /b 1
)

REM Check for required files
if not exist zconf.tab.c (
    echo Error: zconf.tab.c not found. Please run the original build first.
    pause
    exit /b 1
)

REM Use the fixed qmake project file
if exist qconf-windows-fixed.pro (
    echo Using qconf-windows-fixed.pro (with Windows compatibility fixes)...
    qmake qconf-windows-fixed.pro
) else if exist qconf-windows.pro (
    echo Using qconf-windows.pro...
    qmake qconf-windows.pro
) else (
    echo Generating temporary qmake project...
    (
    echo TARGET = qconf
    echo CONFIG += qt console
    echo CONFIG -= app_bundle  
    echo QT += core widgets gui
    echo CONFIG += c++11
    echo QMAKE_CFLAGS += -Wno-sign-compare -Wno-unused-parameter
    echo QMAKE_CXXFLAGS += -Wno-sign-compare -Wno-unused-parameter -Wno-deprecated-declarations
    echo DEFINES += PACKAGE=\\\"qconf\\\" LOCALEDIR=\\\"/usr/share/locale\\\" KBUILD_NO_NLS _WIN32 UNICODE _UNICODE
    echo SOURCES += qconf.cc zconf.tab.c parser_stubs.c
    echo HEADERS += qconf.h lkc.h lkc_proto.h expr.h list.h
    echo INCLUDEPATH += .
    echo win32:LIBS += -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32
    ) > qconf-temp.pro
    qmake qconf-temp.pro
)

if %ERRORLEVEL% neq 0 (
    echo Error: qmake failed
    pause
    exit /b 1
)

REM Build with make (MinGW) or nmake (MSVC)
echo Building...
where mingw32-make >nul 2>nul
if %ERRORLEVEL% equ 0 (
    mingw32-make
) else (
    where make >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        make
    ) else (
        nmake
    )
)

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================
    echo Build successful! qconf.exe created.
    echo ========================================
    echo.
    echo Test with: qconf.exe test_Kconfig
) else (
    echo.
    echo Build failed!
    echo.
    echo For troubleshooting, try:
    echo   build-windows-native.bat  (detailed batch script)
    echo   .\build-windows.ps1       (PowerShell script)
    pause
    exit /b 1
)

REM Clean up temporary files
if exist qconf-temp.pro del qconf-temp.pro

pause
