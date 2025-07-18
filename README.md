# Standalone qconf Build

This directory contains all the necessary files to build qconf (Qt-based Kconfig configurator) independently from the main project.

## Prerequisites

### Linux
- Qt5 development packages:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install qtbase5-dev qtbase5-dev-tools
  
  # CentOS/RHEL/Fedora
  sudo yum install qt5-qtbase-devel
  # or
  sudo dnf install qt5-qtbase-devel
  ```

### Windows
- Qt5 SDK with MinGW or MSVC compiler
- Add Qt5 bin directory to PATH

## Building

### Linux - Using Make
```bash
make
```

### Linux - Using CMake
```bash
mkdir build
cd build
cmake ..
make
```

### Windows
```cmd
build_windows.bat
```

## Installation

### Linux
```bash
sudo make install
```

## Usage

After building, you can use qconf to configure any Kconfig-based project:

```bash
./qconf /path/to/Kconfig
```

## Notes

- The parser files (zconf.tab.c, zconf.lex.c, zconf.hash.c) must be generated from the original project first by running `make menuconfig` or similar.
- This standalone version includes all necessary kconfig library functions.
- The build system supports both Qt4 and Qt5, but Qt5 is recommended.

## Files Included

### Core qconf files:
- qconf.cc, qconf.h - Main Qt application
- images.c - Embedded icons and images

### Kconfig library:
- zconf.tab.c - Generated parser that includes all kconfig functionality
- parser_stubs.c - Minimal stub implementations for missing functions

### Headers:
- lkc.h, lkc_proto.h - Main kconfig headers
- expr.h - Expression definitions
- list.h - Linked list implementation

### Individual source files (for reference):
- confdata.c - Configuration data handling
- symbol.c - Symbol management
- menu.c - Menu structure handling
- expr.c - Expression evaluation
- util.c - Utility functions

### Parser source files (for regeneration if needed):
- zconf.y - Parser grammar
- zconf.l - Lexer rules
- zconf.gperf - Hash function generator
