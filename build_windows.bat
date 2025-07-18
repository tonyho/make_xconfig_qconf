@echo off
REM Windows build script for qconf
REM Requires Qt5 and MinGW or MSVC

echo Building qconf for Windows...

REM Check if Qt5 is available
where qmake >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Qt5 not found in PATH. Please install Qt5 and add it to PATH.
    exit /b 1
)

REM Check for required files
if not exist zconf.tab.c (
    echo Error: zconf.tab.c not found. Please run the original build first.
    exit /b 1
)

REM Generate qmake project file
echo Generating qmake project...
(
echo TARGET = qconf
echo CONFIG += qt
echo QT += core widgets gui
echo DEFINES += PACKAGE=\\\"qconf\\\" LOCALEDIR=\\\"/usr/share/locale\\\" KBUILD_NO_NLS
echo SOURCES += qconf.cc confdata.c symbol.c menu.c expr.c util.c zconf.tab.c
echo HEADERS += qconf.h lkc.h lkc_proto.h expr.h list.h
) > qconf.pro

REM Build with qmake
qmake qconf.pro
if %ERRORLEVEL% neq 0 (
    echo Error: qmake failed
    exit /b 1
)

REM Build with make (MinGW) or nmake (MSVC)
where mingw32-make >nul 2>nul
if %ERRORLEVEL% equ 0 (
    mingw32-make
) else (
    nmake
)

if %ERRORLEVEL% equ 0 (
    echo Build successful! qconf.exe created.
) else (
    echo Build failed!
    exit /b 1
)
