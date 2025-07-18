# Standalone qconf Makefile
# Supports native Linux build and cross-compilation for Windows x64

# Detect build target
ifeq ($(TARGET),win64)
    # Windows x64 cross-compilation using MinGW-w64
    CROSS_PREFIX = x86_64-w64-mingw32-
    CC = $(CROSS_PREFIX)gcc
    CXX = $(CROSS_PREFIX)g++
    WINDRES = $(CROSS_PREFIX)windres
    STRIP = $(CROSS_PREFIX)strip
    
    # Try different Qt5 MinGW paths
    QT5_PREFIX := $(shell find /usr -name "x86_64-w64-mingw32-qt5-qmake" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    ifeq ($(QT5_PREFIX),)
        QT5_PREFIX := $(shell find /usr -name "*mingw*qt5*" -type d 2>/dev/null | head -1)
    endif
    ifeq ($(QT5_PREFIX),)
        $(error MinGW Qt5 not found. Install mingw64-qt5-base-devel or similar package)
    endif
    
    QT5_INCDIR = $(QT5_PREFIX)/include
    QT5_LIBDIR = $(QT5_PREFIX)/lib
    QT5_BINDIR = $(QT5_PREFIX)/bin
    
    QT5_CFLAGS = -I$(QT5_INCDIR) -I$(QT5_INCDIR)/QtCore -I$(QT5_INCDIR)/QtGui -I$(QT5_INCDIR)/QtWidgets -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB
    QT5_LIBS = -L$(QT5_LIBDIR) -lQt5Widgets -lQt5Gui -lQt5Core -lws2_32 -lole32 -loleaut32 -luuid -lwinmm -lgdi32 -lcomdlg32 -loleaut32 -limm32 -lshell32 -lkernel32 -luser32 -ladvapi32
    QT5_MOC = $(QT5_BINDIR)/moc
    
    # Windows-specific flags
    CFLAGS = -O2 -Wall -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_WIN32 -DUNICODE -D_UNICODE
    CXXFLAGS = -std=c++11 -O2 -Wall -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_WIN32 -DUNICODE -D_UNICODE $(QT5_CFLAGS)
    
    EXECUTABLE = qconf.exe
    STRIP_TARGET = qconf-stripped.exe
else
    # Native Linux build
    CC = gcc
    CXX = g++
    STRIP = strip
    
    # Qt5 configuration
    QT5_CFLAGS = $(shell pkg-config --cflags Qt5Core Qt5Gui Qt5Widgets)
    QT5_LIBS = $(shell pkg-config --libs Qt5Core Qt5Gui Qt5Widgets)
    QT5_MOC = $(shell pkg-config --variable=host_bins Qt5Core)/moc
    
    # Compiler flags
    CFLAGS = -O2 -Wall -fPIC -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_GNU_SOURCE
    CXXFLAGS = -std=c++11 -O2 -Wall -fPIC -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_GNU_SOURCE $(QT5_CFLAGS)
    
    EXECUTABLE = qconf
    STRIP_TARGET = qconf-stripped
endif

# Source files
KCONFIG_OBJS = zconf.tab.o parser_stubs.o
QCONF_OBJS = qconf.o

# Default target
all: $(EXECUTABLE)

# Cross-compilation targets
linux: 
	$(MAKE) TARGET=linux

win64:
	$(MAKE) TARGET=win64

# Check for required files
check-files:
	@if [ ! -f zconf.tab.c ]; then \
		echo "Error: zconf.tab.c not found. Please run the original build first."; \
		exit 1; \
	fi

# Check MinGW Qt5 installation for Windows builds
check-mingw-qt5:
ifeq ($(TARGET),win64)
	@if [ -z "$(QT5_PREFIX)" ]; then \
		echo "Error: MinGW Qt5 not found."; \
		echo "Please install one of:"; \
		echo "  - Ubuntu/Debian: apt-get install qtbase5-dev-tools mingw-w64 qt5-qmake-bin"; \
		echo "  - Fedora: dnf install mingw64-qt5-qtbase-devel mingw64-qt5-qttools"; \
		echo "  - Arch: pacman -S mingw-w64-qt5-base mingw-w64-qt5-tools"; \
		exit 1; \
	fi
	@echo "Using Qt5 from: $(QT5_PREFIX)"
endif

# Generate MOC file
qconf.moc: qconf.h check-mingw-qt5
	$(QT5_MOC) -i $< -o $@

# Compile C files
%.o: %.c check-mingw-qt5
	$(CC) $(CFLAGS) -c $< -o $@

# Compile C++ files
qconf.o: qconf.cc qconf.moc
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Link executable
$(EXECUTABLE): check-files $(KCONFIG_OBJS) $(QCONF_OBJS)
	$(CXX) -o $@ $(KCONFIG_OBJS) $(QCONF_OBJS) $(QT5_LIBS)

# Create stripped version
$(STRIP_TARGET): $(EXECUTABLE)
	cp $(EXECUTABLE) $(STRIP_TARGET)
	$(STRIP) $(STRIP_TARGET)

# Release targets
release-linux: linux $(STRIP_TARGET)
	./scripts/package-linux.sh

release-win64: win64 $(STRIP_TARGET)
	./scripts/package-windows.sh

release-all: release-linux release-win64

# Clean
clean:
	rm -f *.o qconf.moc qconf qconf.exe qconf-stripped qconf-stripped.exe
	rm -rf releases/

# Install (Linux only)
install: linux
	install -D qconf $(DESTDIR)/usr/bin/qconf

.PHONY: all linux win64 clean install check-files check-mingw-qt5 release-linux release-win64 release-all
