# Need make menuconfig(mconf) version?

Get it from [this repository](https://github.com/tonyho/make_menuconfig_mconf)

## Git it for Windows/Linux

Just download it from the release page.

## Building

Check the github action script in the .github/workflow, which has the commands to build it one both Windows and Linux.

## Usage

After building or installing, you can use qconf to configure any Kconfig-based project:

```bash
# Linux
./qconf /path/to/Kconfig
qconf /path/to/Kconfig          # If installed

# Windows
qconf.exe Kconfig
qconf.bat Kconfig               # Using batch wrapper
.\qconf.ps1 Kconfig             # Using PowerShell wrapper
```

## Cross-Compilation Requirements

### For Windows x64 Cross-Compilation on Linux

#### Ubuntu/Debian:
```bash
# Basic MinGW-w64 toolchain
sudo apt-get install mingw-w64 mingw-w64-tools

# Qt5 for MinGW (may require additional repositories)
sudo apt-get install qt5-qmake-bin
# or build Qt5 with MXE: https://mxe.cc/
```

#### Fedora:
```bash
# MinGW-w64 toolchain and Qt5
sudo dnf install mingw64-gcc mingw64-gcc-c++ mingw64-qt5-qtbase-devel mingw64-qt5-qttools
```

#### Arch Linux:
```bash
# MinGW-w64 and Qt5
sudo pacman -S mingw-w64-gcc mingw-w64-qt5-base mingw-w64-qt5-tools
```

#### Using MXE (Cross-platform):
```bash
# Clone and build MXE with Qt5
git clone https://github.com/mxe/mxe.git
cd mxe
make MXE_TARGETS=x86_64-w64-mingw32.shared qt5
```

## Notes

- This standalone version includes all necessary kconfig library functions.
- The build system supports both Qt4 and Qt5, but Qt5 is recommended.
- Cross-compilation produces fully portable Windows executables with all dependencies included.

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
