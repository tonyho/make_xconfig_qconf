#!/bin/bash
# Linux release packaging script for qconf

set -e

VERSION=${VERSION:-$(date +%Y%m%d)}
RELEASE_NAME="qconf-linux-x64-${VERSION}"
RELEASE_DIR="releases/${RELEASE_NAME}"

echo "Creating Linux release package..."

# Create release directory
mkdir -p "${RELEASE_DIR}"

# Copy executable
if [ -f "qconf-stripped" ]; then
    cp qconf-stripped "${RELEASE_DIR}/qconf"
else
    cp qconf "${RELEASE_DIR}/qconf"
fi

# Make executable
chmod +x "${RELEASE_DIR}/qconf"

# Copy documentation
cp README.md "${RELEASE_DIR}/"
cp test_Kconfig "${RELEASE_DIR}/"

# Create install script
cat > "${RELEASE_DIR}/install.sh" << 'EOF'
#!/bin/bash
# qconf installation script

set -e

INSTALL_DIR="${1:-/usr/local/bin}"

echo "Installing qconf to ${INSTALL_DIR}..."

# Check if we have write permission
if [ ! -w "$(dirname "${INSTALL_DIR}")" ]; then
    echo "Error: No write permission to ${INSTALL_DIR}"
    echo "Try running with sudo or specify a different directory:"
    echo "  ./install.sh ~/bin"
    exit 1
fi

# Create directory if it doesn't exist
mkdir -p "${INSTALL_DIR}"

# Copy executable
cp qconf "${INSTALL_DIR}/qconf"
chmod +x "${INSTALL_DIR}/qconf"

echo "qconf installed successfully to ${INSTALL_DIR}/qconf"
echo ""
echo "Usage: qconf <Kconfig-file>"
echo "Test:  qconf test_Kconfig"
EOF

chmod +x "${RELEASE_DIR}/install.sh"

# Create usage instructions
cat > "${RELEASE_DIR}/USAGE.txt" << 'EOF'
qconf - Qt-based Kconfig Configuration Tool
==========================================

INSTALLATION:
  Run: ./install.sh [install-directory]
  Default install directory: /usr/local/bin
  
  Examples:
    ./install.sh                    # Install to /usr/local/bin (may need sudo)
    ./install.sh ~/bin              # Install to ~/bin
    sudo ./install.sh /usr/bin      # Install to /usr/bin

USAGE:
  qconf <Kconfig-file>
  
  Examples:
    ./qconf test_Kconfig            # Test with included sample
    qconf /path/to/your/Kconfig     # Use with your project

REQUIREMENTS:
  - Qt5 libraries (libqt5widgets5, libqt5gui5, libqt5core5)
  - X11 display for GUI

TROUBLESHOOTING:
  If you get "command not found", make sure the install directory is in your PATH:
    export PATH="$PATH:/usr/local/bin"
    
  If you get Qt library errors, install Qt5:
    Ubuntu/Debian: sudo apt-get install qt5-default
    CentOS/RHEL:   sudo yum install qt5-qtbase-gui
    Fedora:        sudo dnf install qt5-qtbase-gui
EOF

# Get library dependencies
echo "Checking library dependencies..."
if command -v ldd >/dev/null 2>&1; then
    if [ -f "qconf-stripped" ]; then
        ldd qconf-stripped > "${RELEASE_DIR}/DEPENDENCIES.txt" 2>/dev/null || echo "Could not determine dependencies" > "${RELEASE_DIR}/DEPENDENCIES.txt"
    else
        ldd qconf > "${RELEASE_DIR}/DEPENDENCIES.txt" 2>/dev/null || echo "Could not determine dependencies" > "${RELEASE_DIR}/DEPENDENCIES.txt"
    fi
fi

# Create tarball
cd releases
tar -czf "${RELEASE_NAME}.tar.gz" "${RELEASE_NAME}"
cd ..

echo "Linux release created: releases/${RELEASE_NAME}.tar.gz"
echo "Contents:"
ls -la "${RELEASE_DIR}/"