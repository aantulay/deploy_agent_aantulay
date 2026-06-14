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

# GENERATE SOURCE FILES

cat > "$PROJECT_DIR/attendance_checker.py" << 'PYEOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
PYEOF

cat > "$PROJECT_DIR/Helpers/assets.csv" << 'CSVEOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSVEOF

cat > "$PROJECT_DIR/Helpers/config.json" << 'JSONEOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
JSONEOF

cat > "$PROJECT_DIR/reports/reports.log" << 'LOGEOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
LOGEOF

echo "[OK] Source files generated."

# DYNAMIC CONFIGURATION

CONFIG_PATH="$PROJECT_DIR/Helpers/config.json"

read -p "Update attendance thresholds? (y/n): " UPDATE_CHOICE

if [ "$UPDATE_CHOICE" = "y" ] || [ "$UPDATE_CHOICE" = "Y" ]; then
    read -p "Enter WARNING threshold % (default 75): " WARNING_INPUT
    read -p "Enter FAILURE threshold % (default 50): " FAILURE_INPUT

    WARNING_INPUT=${WARNING_INPUT:-75}
    FAILURE_INPUT=${FAILURE_INPUT:-50}

    if ! [[ "$WARNING_INPUT" =~ ^[0-9]+$ ]] || ! [[ "$FAILURE_INPUT" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] Thresholds must be whole numbers. Keeping existing values."
    else
        sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING_INPUT/" "$CONFIG_PATH"
        sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE_INPUT/" "$CONFIG_PATH"
        echo "[OK] Thresholds updated -> warning=$WARNING_INPUT, failure=$FAILURE_INPUT"
    fi
else
    echo "[*] Keeping default thresholds (75 / 50)."
fi

# ENVIRONMENT VALIDATION

if python3 --version >/dev/null 2>&1; then
    echo "[OK] Health check passed: $(python3 --version) is installed."
else
    echo "[WARNING] python3 not found. attendance_checker.py will not run."
fi

# FINAL VERIFICATION

for path in \
    "$PROJECT_DIR/attendance_checker.py" \
    "$PROJECT_DIR/Helpers/assets.csv" \
    "$PROJECT_DIR/Helpers/config.json" \
    "$PROJECT_DIR/reports/reports.log"; do
    if [ -f "$path" ]; then
        echo "$path exists"
    else
        echo "MISSING: $path"
    fi
done

trap - SIGINT
echo ""
echo "[DONE] Project '$PROJECT_DIR' is ready."
