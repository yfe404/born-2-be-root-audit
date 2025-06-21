#!/bin/bash

# Born2beroot Automated Audit Script
# This script checks the implementation of the mandatory and bonus requirements for the Born2beroot project.

LOG_FILE="/home/yann/born2beroot_audit.log"
> "$LOG_FILE" # Clear the log file

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log_section() {
    log ""
    log "=== $1 ==="
}

# --- 1. Check Operating System ---
log_section "Operating System Check"
OS=$(lsb_release -d | awk -F"\t" '{print $2}')
if [[ "$OS" == *"Debian"* || "$OS" == *"Rocky"* ]]; then
    log "[OK] Operating System: $OS"
else
    log "[ERROR] Unsupported OS: $OS. Must be Debian or Rocky."
fi

# --- 2. Check for Graphical Interface ---
log_section "Graphical Interface Check"
if dpkg -l | grep -q xorg; then
    log "[ERROR] Graphical interface (X.org) is installed. This is not allowed."
else
    log "[OK] No graphical interface detected."
fi

# --- 3. Check AppArmor or SELinux ---
log_section "AppArmor/SELinux Check"
if [[ "$OS" == *"Debian"* ]]; then
    if systemctl is-active --quiet apparmor; then
        log "[OK] AppArmor is running."
    else
        log "[ERROR] AppArmor is not running."
    fi
elif [[ "$OS" == *"Rocky"* ]]; then
    if sestatus | grep -q "enabled"; then
        log "[OK] SELinux is enabled."
    else
        log "[ERROR] SELinux is not enabled."
    fi
fi

# --- 4. Check Partitioning ---
log_section "Partitioning Check"
EXPECTED_PARTITIONS=("boot" "root" "swap" "home")
for part in "${EXPECTED_PARTITIONS[@]}"; do
	if lsblk | grep -q "$part"; then
		log "[OK] Partition $part exists."
	else
		log "[ERROR] Partition $part is missing."
	fi
done

# Bonus: Check for additional partitions
BONUS_PARTITIONS=("var" "srv" "tmp")
for part in "${BONUS_PARTITIONS[@]}"; do
    if echo "$PARTITIONS" | grep -q "$part"; then
        log "[OK] Bonus partition $part exists."
    else
        log "[WARNING] Bonus partition $part is missing."
    fi
done

# --- 5. Check Encrypted LVM ---
log_section "Encrypted LVM Check"
if lsblk | grep -q "crypt"; then
    log "[OK] Encrypted LVM is configured."
else
    log "[ERROR] Encrypted LVM is not configured."
fi

# --- 6. Check UFW Firewall ---
log_section "UFW Firewall Check"
if systemctl is-active --quiet ufw; then
    log "[OK] UFW is active."
    log "UFW Rules:"
    sudo ufw status verbose | tee -a "$LOG_FILE"
else
    log "[ERROR] UFW is not active."
fi

# --- 7. Check Password Policy ---
log_section "Password Policy Check"
PASSWD_POLICY=$(grep -E '^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_MIN_LEN' /etc/login.defs)
if echo "$PASSWD_POLICY" | grep -q "PASS_MIN_LEN.*[0-9]\{8,\}"; then
    log "[OK] Password minimum length is set to 8 or more."
else
    log "[ERROR] Password minimum length is less than 8."
fi

if echo "$PASSWD_POLICY" | grep -q "PASS_MAX_DAYS.*[0-9]\{90,\}"; then
    log "[OK] Password maximum age is set to 90 days or more."
else
    log "[ERROR] Password maximum age is less than 90 days."
fi

# --- 8. Check Sudo Configuration ---
log_section "Sudo Configuration Check"
if grep -q "^%sudo.*ALL=(ALL:ALL) ALL" /etc/sudoers; then
    log "[OK] Sudoers file allows members of the sudo group to execute any command."
else
    log "[ERROR] Sudoers file does not allow members of the sudo group to execute any command."
fi

if grep -q "^Defaults.*requiretty" /etc/sudoers; then
    log "[ERROR] Sudoers file requires a TTY for sudo commands. This is not recommended."
else
    log "[OK] Sudoers file does not require a TTY."
fi

# --- 9. Bonus: Check WordPress Setup ---
log_section "WordPress Setup Check"
if systemctl is-active --quiet lighttpd && systemctl is-active --quiet mariadb; then
    log "[OK] Lighttpd and MariaDB are running."
    if [[ -d "/var/www/html/wordpress" ]]; then
        log "[OK] WordPress directory exists."
    else
        log "[WARNING] WordPress directory is missing."
    fi
else
    log "[ERROR] Lighttpd or MariaDB is not running."
fi

# --- 10. Bonus: Check Additional Service ---
log_section "Additional Service Check"
SERVICE_NAME="<your_service_name>" # Replace with your chosen service
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "[OK] Additional service ($SERVICE_NAME) is running."
else
    log "[WARNING] Additional service ($SERVICE_NAME) is not running."
fi

log ""
log "Audit Complete. Results saved to $LOG_FILE."

