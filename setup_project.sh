#!/usr/bin/env bash

# GLOBAL VARIABLES

PROJECT_INPUT=""
PROJECT_DIR=""
ARCHIVE_NAME=""

# SIGNAL TRAP

cleanup_on_interrupt() {
    echo "[!] Interrupt (Ctrl+C) detected. Rolling back the build..."
    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR" 2>/dev/null
        echo "[*] Partial work archived to: ${ARCHIVE_NAME}.tar.gz"
        rm -rf "$PROJECT_DIR"
        echo "[*] Incomplete directory removed: $PROJECT_DIR"
    else
        echo "[*] Nothing to clean up yet."
    fi
    exit 1
}
trap cleanup_on_interrupt SIGINT
