# qconf Windows native build project file (with fixes)
# Use with: qmake qconf-windows-fixed.pro && mingw32-make

TARGET = qconf
CONFIG += qt console
CONFIG -= app_bundle
QT += core widgets gui

# Compiler settings
CONFIG += c++11
QMAKE_CXXFLAGS += -std=c++11

# Windows-specific compiler flags to suppress warnings
QMAKE_CFLAGS += -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-implicit-fallthrough -Wno-builtin-declaration-mismatch -Wno-pointer-to-int-cast -Wno-dangling-pointer
QMAKE_CXXFLAGS += -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-deprecated-declarations -Wno-implicit-fallthrough -Wno-unused-variable

# Defines
DEFINES += PACKAGE=\\\"qconf\\\"
DEFINES += LOCALEDIR=\\\"/usr/share/locale\\\"
DEFINES += KBUILD_NO_NLS
DEFINES += _WIN32
DEFINES += UNICODE
DEFINES += _UNICODE
DEFINES += QT_MOC_CPP

# Source files
SOURCES += qconf.cc \
           zconf.tab.c \
           parser_stubs.c

# Header files  
HEADERS += qconf.h \
           lkc.h \
           lkc_proto.h \
           expr.h \
           list.h

# Include directories
INCLUDEPATH += .

# Windows-specific libraries
win32 {
    LIBS += -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32
}

# Output directory
DESTDIR = .

# Intermediate files directory
OBJECTS_DIR = build/obj
MOC_DIR = build/moc
RCC_DIR = build/rcc
UI_DIR = build/ui

# Clean up
QMAKE_CLEAN += qconf.exe