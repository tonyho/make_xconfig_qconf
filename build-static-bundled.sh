#!/bin/bash

# Build script for qconf with static Qt bundled libraries
# This script ensures we use only the custom Qt installation

set -e

# Set Qt installation path
QT_STATIC_PATH="/ExtDisk/Projects/VSC_IDE/telink_w91_wifi_sdk/wits-sdk/qconf_standalone/install_static"

# Clean previous build
echo "Cleaning previous build..."
rm -rf build/obj-static-bundled build/moc-static-bundled build/rcc-static-bundled build/ui-static-bundled
rm -f qconf-static-bundled Makefile

# Set environment to use only our Qt installation
export QTDIR="$QT_STATIC_PATH"
export PATH="$QT_STATIC_PATH/bin:$PATH"
export LD_LIBRARY_PATH="$QT_STATIC_PATH/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$QT_STATIC_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"

# Clear any system Qt environment variables
unset QT_SELECT
unset QT_QPA_PLATFORM_PLUGIN_PATH

echo "Using Qt from: $QT_STATIC_PATH"
echo "qmake version:"
"$QT_STATIC_PATH/bin/qmake" -version

# Generate Makefile
echo "Generating Makefile..."
"$QT_STATIC_PATH/bin/qmake" qconf-static-bundled.pro

# Build
echo "Building..."
make

echo "Build completed successfully!"
echo "Executable: ./qconf-static-bundled"