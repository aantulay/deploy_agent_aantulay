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

# PROJECT NAME

read -p "Enter a tag for this project (e.g. v1): " PROJECT_INPUT

if [ -z "$PROJECT_INPUT" ]; then
    echo "[ERROR] No project tag provided. Aborting."
    exit 1
fi

PROJECT_DIR="attendance_tracker_${PROJECT_INPUT}"
ARCHIVE_NAME="attendance_tracker_${PROJECT_INPUT}_archive"

# DIRECTORY STRUCTURE

if [ -d "$PROJECT_DIR" ]; then
    echo "[ERROR] '$PROJECT_DIR' already exists. Aborting to avoid overwriting."
    exit 1
fi

if ! mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports" 2>/dev/null; then
    echo "[ERROR] Could not create directories (permission denied?). Aborting."
    exit 1
fi
echo "[OK] Directory structure created."
