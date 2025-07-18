# CMake toolchain file for MinGW-w64 cross-compilation

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Cross-compilation tools
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)

# Target environment
set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)

# Search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Search for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Qt5 paths for MinGW
set(Qt5_DIR "/usr/x86_64-w64-mingw32/lib/cmake/Qt5" CACHE PATH "Qt5 CMake directory")

# Additional library paths
list(APPEND CMAKE_PREFIX_PATH 
    "/usr/x86_64-w64-mingw32"
    "/usr/lib/mxe/usr/x86_64-w64-mingw32.shared"
    "/usr/lib/mxe/usr/x86_64-w64-mingw32.static"
)

# Windows-specific flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libgcc")

# Enable static linking for MinGW
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -static-libgcc -static-libstdc++")