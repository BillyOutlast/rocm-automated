#!/bin/bash

#############################################################################
# Schedule Daily Builds Script
#
# This script sets up automated daily builds using cron or systemd timers
# Run this on a server to schedule daily Docker image builds
#
# Usage:
#   sudo ./schedule-daily-builds.sh [method]
#
# Methods:
#   cron      - Use cron for scheduling (default)
#   systemd   - Use systemd timer
#   remove    - Remove scheduled builds
#############################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPT="${SCRIPT_DIR}/daily-build.sh"
LOG_DIR="${SCRIPT_DIR}/logs"
CRON_TIME="0 2 * * *"  # 2:00 AM daily
SCHEDULE_METHOD="${1:-cron}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root for system-wide scheduling"
        print_info "Run with: sudo $0"
        exit 1
    fi
}

create_log_dir() {
    print_info "Creating log directory..."
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
}

setup_cron() {
    print_info "Setting up cron job for daily builds..."
    
    # Make build script executable
    chmod +x "$BUILD_SCRIPT"
    
    # Create log directory
    create_log_dir
    
    # Cron job command
    CRON_CMD="cd ${SCRIPT_DIR} && ${BUILD_SCRIPT} --push >> ${LOG_DIR}/daily-build-\$(date +\%Y-\%m-\%d).log 2>&1"
    CRON_ENTRY="${CRON_TIME} ${CRON_CMD}"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "${BUILD_SCRIPT}"; echo "$CRON_ENTRY") | crontab -
    
    print_info "Cron job installed successfully!"
    echo ""
    echo "Schedule: Daily at 2:00 AM"
    echo "Logs: ${LOG_DIR}/daily-build-YYYY-MM-DD.log"
    echo ""
    echo "Current crontab:"
    crontab -l | grep "${BUILD_SCRIPT}"
}

setup_systemd() {
    print_info "Setting up systemd timer for daily builds..."
    
    # Make build script executable
    chmod +x "$BUILD_SCRIPT"
    
    # Create log directory
    create_log_dir
    
    # Create systemd service
    SERVICE_FILE="/etc/systemd/system/rocm-daily-build.service"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=ROCm Daily Docker Image Build
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
User=root
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${BUILD_SCRIPT} --push
StandardOutput=append:${LOG_DIR}/daily-build.log
StandardError=append:${LOG_DIR}/daily-build-error.log
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF
    
    # Create systemd timer
    TIMER_FILE="/etc/systemd/system/rocm-daily-build.timer"
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=ROCm Daily Docker Image Build Timer
Requires=rocm-daily-build.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true
RandomizedDelaySec=0

[Install]
WantedBy=timers.target
EOF
    
    # Reload systemd and enable timer
    systemctl daemon-reload
    systemctl enable rocm-daily-build.timer
    systemctl start rocm-daily-build.timer
    
    print_info "Systemd timer installed successfully!"
    echo ""
    echo "Service: rocm-daily-build.service"
    echo "Timer: rocm-daily-build.timer"
    echo "Schedule: Daily at 2:00 AM"
    echo "Logs: ${LOG_DIR}/daily-build.log"
    echo ""
    echo "Timer status:"
    systemctl status rocm-daily-build.timer --no-pager
}

remove_cron() {
    print_info "Removing cron job..."
    crontab -l 2>/dev/null | grep -v "${BUILD_SCRIPT}" | crontab -
    print_info "Cron job removed"
}

remove_systemd() {
    print_info "Removing systemd timer..."
    
    systemctl stop rocm-daily-build.timer 2>/dev/null || true
    systemctl disable rocm-daily-build.timer 2>/dev/null || true
    
    rm -f /etc/systemd/system/rocm-daily-build.service
    rm -f /etc/systemd/system/rocm-daily-build.timer
    
    systemctl daemon-reload
    
    print_info "Systemd timer removed"
}

show_status() {
    echo "==================================================================="
    echo "Daily Build Schedule Status"
    echo "==================================================================="
    echo ""
    
    # Check cron
    echo "Cron Jobs:"
    if crontab -l 2>/dev/null | grep -q "${BUILD_SCRIPT}"; then
        crontab -l | grep "${BUILD_SCRIPT}"
    else
        echo "  No cron jobs found"
    fi
    echo ""
    
    # Check systemd
    echo "Systemd Timers:"
    if systemctl list-timers rocm-daily-build.timer --no-pager 2>/dev/null | grep -q rocm-daily-build; then
        systemctl list-timers rocm-daily-build.timer --no-pager
    else
        echo "  No systemd timers found"
    fi
    echo ""
    
    # Recent logs
    if [ -d "$LOG_DIR" ] && [ "$(ls -A $LOG_DIR 2>/dev/null)" ]; then
        echo "Recent Build Logs:"
        ls -lht "$LOG_DIR" | head -5
    fi
}

# Main script
case "$SCHEDULE_METHOD" in
    cron)
        check_root
        setup_cron
        ;;
    systemd)
        check_root
        setup_systemd
        ;;
    remove)
        check_root
        remove_cron
        remove_systemd
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {cron|systemd|remove|status}"
        echo ""
        echo "  cron     - Schedule using cron (default)"
        echo "  systemd  - Schedule using systemd timer"
        echo "  remove   - Remove all scheduled builds"
        echo "  status   - Show current schedule status"
        exit 1
        ;;
esac
