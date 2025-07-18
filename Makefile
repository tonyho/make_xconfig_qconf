# Standalone qconf Makefile
# Requires Qt5 development packages

CC = gcc
CXX = g++

# Qt5 configuration
QT5_CFLAGS = $(shell pkg-config --cflags Qt5Core Qt5Gui Qt5Widgets)
QT5_LIBS = $(shell pkg-config --libs Qt5Core Qt5Gui Qt5Widgets)
QT5_MOC = $(shell pkg-config --variable=host_bins Qt5Core)/moc

# Compiler flags
CFLAGS = -O2 -Wall -fPIC -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_GNU_SOURCE
CXXFLAGS = -std=c++11 -O2 -Wall -fPIC -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_GNU_SOURCE $(QT5_CFLAGS)

# Source files
KCONFIG_OBJS = zconf.tab.o parser_stubs.o
QCONF_OBJS = qconf.o

# Default target
all: qconf

# Check for required files
check-files:
	@if [ ! -f zconf.tab.c ]; then \
		echo "Error: zconf.tab.c not found. Please run the original build first."; \
		exit 1; \
	fi

# Generate MOC file
qconf.moc: qconf.h
	$(QT5_MOC) -i $< -o $@

# Compile C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Compile C++ files
qconf.o: qconf.cc qconf.moc
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Link qconf
qconf: check-files $(KCONFIG_OBJS) $(QCONF_OBJS)
	$(CXX) -o $@ $(KCONFIG_OBJS) $(QCONF_OBJS) $(QT5_LIBS)

# Clean
clean:
	rm -f *.o qconf.moc qconf

# Install
install: qconf
	install -D qconf $(DESTDIR)/usr/bin/qconf

.PHONY: all clean install check-files
