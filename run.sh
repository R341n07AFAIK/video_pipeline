#!/bin/bash

# Video Pipeline - Unix/Linux/macOS Launcher
# This script launches the PowerShell run script on Unix-like systems

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if PowerShell is available
if ! command -v pwsh &> /dev/null; then
    echo "ERROR: PowerShell Core (pwsh) is not installed"
    echo "Install from: https://github.com/PowerShell/PowerShell/releases"
    exit 1
fi

# Launch PowerShell run script with any arguments
pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run.ps1" "$@"
