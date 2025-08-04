# qconf static build with bundled Qt libraries
# Use with: /ExtDisk/Projects/VSC_IDE/telink_w91_wifi_sdk/wits-sdk/qconf_standalone/install_static/bin/qmake qconf-static-bundled.pro && make
# This creates a fully static executable using Qt with bundled libraries

TARGET = qconf-static-bundled
CONFIG += qt console static staticlib
CONFIG -= app_bundle shared
QT += core widgets gui

# Compiler settings
CONFIG += c++11
QMAKE_CXXFLAGS += -std=c++11

# Static build configuration
DEFINES += STATIC_BUILD
message("Building qconf with bundled Qt libraries")

# Set custom Qt installation path
QT_INSTALL_PREFIX = /ExtDisk/Projects/VSC_IDE/telink_w91_wifi_sdk/wits-sdk/qconf_standalone/install_static

# Completely override Qt paths - use only our static installation
QMAKE_INCDIR_QT = $$QT_INSTALL_PREFIX/include
QMAKE_LIBDIR_QT = $$QT_INSTALL_PREFIX/lib

# Override all Qt tool paths
QMAKE_MOC = $$QT_INSTALL_PREFIX/bin/moc
QMAKE_UIC = $$QT_INSTALL_PREFIX/bin/uic
QMAKE_RCC = $$QT_INSTALL_PREFIX/bin/rcc

# Clear all system include and library paths
INCLUDEPATH = . $$QT_INSTALL_PREFIX/include
QMAKE_INCDIR = 
QMAKE_LIBDIR = $$QT_INSTALL_PREFIX/lib

# Static linking flags (allow dynamic linking for system libraries)
QMAKE_LFLAGS += -static-libgcc -static-libstdc++

# Force static Qt plugins for Linux (minimal set since no OpenGL)
CONFIG += static
QTPLUGIN += qlinuxfb qminimal

# Linux-specific compiler flags to suppress warnings
QMAKE_CFLAGS += -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-implicit-fallthrough -Wno-builtin-declaration-mismatch -Wno-pointer-to-int-cast -Wno-dangling-pointer
QMAKE_CXXFLAGS += -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-deprecated-declarations -Wno-implicit-fallthrough -Wno-unused-variable

# Defines
DEFINES += PACKAGE=\\\"qconf\\\"
DEFINES += LOCALEDIR=\\\"/usr/share/locale\\\"
DEFINES += KBUILD_NO_NLS
DEFINES += UNICODE
DEFINES += _UNICODE
DEFINES += QT_MOC_CPP
DEFINES += QT_STATICPLUGIN

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

# Manually specify all library dependencies in correct order
LIBS = -L$$QT_INSTALL_PREFIX/lib

# Core Qt libraries (order matters for static linking)
LIBS += -lQt5Widgets
LIBS += -lQt5Gui  
LIBS += -lQt5Core

# Qt support libraries for minimal/framebuffer platforms
LIBS += -lQt5FontDatabaseSupport
LIBS += -lQt5EventDispatcherSupport
LIBS += -lQt5ServiceSupport
LIBS += -lQt5ThemeSupport
LIBS += -lQt5FbSupport
LIBS += -lQt5DeviceDiscoverySupport
LIBS += -lQt5InputSupport

# Qt bundled third-party libraries
LIBS += -lqtfreetype
LIBS += -lqtharfbuzz  
LIBS += -lqtlibpng
LIBS += -lqtlibjpeg
LIBS += -lqtpcre2

# Platform plugins
LIBS += -L$$QT_INSTALL_PREFIX/plugins/platforms
LIBS += -lqlinuxfb
LIBS += -lqminimal

# System libraries (minimal set)
LIBS += -L/usr/lib/x86_64-linux-gnu
LIBS += -ldl -lpthread -lrt -lm -lz

# Output directory
DESTDIR = .

# Intermediate files directory
OBJECTS_DIR = build/obj-static-bundled
MOC_DIR = build/moc-static-bundled
RCC_DIR = build/rcc-static-bundled
UI_DIR = build/ui-static-bundled

# Clean up
QMAKE_CLEAN += qconf-static-bundled

# Build messages
message("Static build configuration:")
message("  Target: $$TARGET")
message("  Qt Installation: $$QT_INSTALL_PREFIX")
message("  Output: $$DESTDIR/$$TARGET")
message("  Static linking: enabled")
message("  Qt plugins: qlinuxfb, qminimal (no X11 dependencies)")
message("  Bundled libraries: freetype, harfbuzz, png, jpeg, pcre2")
message("  Use qmake from: $$QT_INSTALL_PREFIX/bin/qmake")