#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name: backup_galera.sh
# Description: Tool designed to help you backup a MariaDB Galera cluster
# Author: peterweissdk
# Email: peterweissdk@flems.dk
# Date: 2025-03-26
# Version: v0.1.0
# Usage: Run script, or add it to cron
# ----------------------------------------------------------------------------

# Variables
BACKUP_DIR='/backup'
BACKUP_SUB_DIR='temp'
LOG_DIR='/logs'
LOG_FILE="${LOG_DIR}/galera_backup.log"
MAX_DESYNC_WAIT=30  # Maximum wait time in seconds for desync
MAX_SYNC_WAIT=60  # Maximum wait time in seconds for sync
WAIT_INTERVAL=5  # Check every 5 seconds
TODAY=$(date +"%Y%m%d")
BACKUP_TODAY="galera-mariadb_dump-$TODAY.sql"

# Write to log file
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
    
    # Print to stdout, errors to stderr
    if [ "$level" = "ERROR" ]; then
        echo "[${timestamp}] [${level}] ${message}" >&2
    else
        echo "${message}"
    fi
}

# Initialize environment and create necessary directories/files
init() {
    # Create log directory and file if they don't exist
    mkdir -p "${LOG_DIR}"
    if [ ! -d "${LOG_DIR}" ]; then
        echo "ERROR: Failed to create log directory ${LOG_DIR}" >&2
        exit 1
    fi
    chmod 755 "${LOG_DIR}"  # rwxr-xr-x
    
    if [ ! -f "${LOG_FILE}" ]; then
        touch "${LOG_FILE}"
        if [ ! -f "${LOG_FILE}" ]; then
            echo "ERROR: Failed to create log file ${LOG_FILE}" >&2
            exit 1
        fi
        chmod 644 "${LOG_FILE}"  # rw-r--r--
    fi

    # Test if we can write to the log file
    if ! echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Log system initialized" >> "${LOG_FILE}"; then
        echo "ERROR: Cannot write to log file ${LOG_FILE}" >&2
        exit 1
    fi
    
    # Source environment variables
    if [ -f .env ]; then
        source .env
        log "INFO" "Environment variables loaded successfully"
    else
        log "ERROR" "Environment file (.env) not found"
        exit 1
    fi

    # Check for required root password
    if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
        log "ERROR" "MYSQL_ROOT_PASSWORD is not set in .env file"
        exit 1
    fi
    log "INFO" "Required environment variables verified"

    # Create backup directories if they don't exist
    mkdir -p "${BACKUP_DIR}/${BACKUP_SUB_DIR}"
    chmod 755 "${BACKUP_DIR}"  # rwxr-xr-x
    chmod 755 "${BACKUP_DIR}/${BACKUP_SUB_DIR}"  # rwxr-xr-x
    log "INFO" "Backup directories initialized"
    
    log "INFO" "Initialization completed"
}

# Function to desync the database
desync_database() {
    log "INFO" "Starting database desync"
    docker exec mariadb-galera mariadb -p"${MYSQL_ROOT_PASSWORD}" -u root --execute "SET GLOBAL wsrep_desync = ON"

    log "INFO" "Waiting for desync to take effect..."
    for ((i=0; i<=$MAX_DESYNC_WAIT; i+=$WAIT_INTERVAL)); do
        DESYNC_STATUS=$(docker exec mariadb-galera mariadb -p"${MYSQL_ROOT_PASSWORD}" -u root --execute "SHOW VARIABLES LIKE 'wsrep_desync'" | grep -o "ON")
        
        if [ "$DESYNC_STATUS" = "ON" ]; then
            log "INFO" "Database successfully desynced"
            return 0
        elif [ $i -eq $MAX_DESYNC_WAIT ]; then
            log "ERROR" "Failed to desync the database within ${MAX_DESYNC_WAIT} seconds. Status: ${DESYNC_STATUS}"
            exit 1
        else
            log "INFO" "Waiting for desync... (${i}s/${MAX_DESYNC_WAIT}s)"
            sleep $WAIT_INTERVAL
        fi
    done
}

# Function to create backup
create_backup() {
    log "INFO" "Starting backup creation"

    # Create Mariadb dump
    log "INFO" "Creating Mariadb dump..."
    if ! docker exec mariadb-galera mariadb-dump --flush-logs -u root -p"${MYSQL_ROOT_PASSWORD}" --all-databases > "${BACKUP_DIR}/${BACKUP_SUB_DIR}/${BACKUP_TODAY}"; then
        log "ERROR" "Failed to create Mariadb dump"
        enable_sync
        exit 1
    fi
    log "INFO" "Mariadb dump created successfully"

    # Create tar archive
    log "INFO" "Creating tar archive..."
    if ! (cd "${BACKUP_DIR}/${BACKUP_SUB_DIR}" && tar -czf "${BACKUP_DIR}/galera-backup-${TODAY}.tar.gz" "${BACKUP_TODAY}"); then
        log "ERROR" "Failed to create tar archive"
        enable_sync
        exit 1
    fi
    log "INFO" "Tar archive created successfully"

    # Clean up temp files
    log "INFO" "Cleaning up temporary files..."
    rm -f "${BACKUP_DIR}/${BACKUP_SUB_DIR}/${BACKUP_TODAY}"
    log "INFO" "Temporary files cleaned up"
}

# Function to enable sync
enable_sync() {
    log "INFO" "Starting database sync"
    docker exec mariadb-galera mariadb -p"${MYSQL_ROOT_PASSWORD}" -u root --execute "SET GLOBAL wsrep_desync = OFF"

    log "INFO" "Waiting for node to be fully synced..."
    for ((i=0; i<=$MAX_SYNC_WAIT; i+=$WAIT_INTERVAL)); do
        # Check both wsrep_desync and wsrep_local_state_comment
        DESYNC_STATUS=$(docker exec mariadb-galera mariadb -p"${MYSQL_ROOT_PASSWORD}" -u root --execute "SHOW VARIABLES LIKE 'wsrep_desync'" | grep -o "OFF")
        SYNC_STATE=$(docker exec mariadb-galera mariadb -p"${MYSQL_ROOT_PASSWORD}" -u root --execute "SHOW STATUS LIKE 'wsrep_local_state_comment'" | grep -o "Synced")
        
        if [ "$DESYNC_STATUS" = "OFF" ] && [ "$SYNC_STATE" = "Synced" ]; then
            log "INFO" "Node is fully synchronized"
            return 0
        elif [ $i -eq $MAX_SYNC_WAIT ]; then
            log "ERROR" "Node failed to synchronize within ${MAX_SYNC_WAIT} seconds. Desync: ${DESYNC_STATUS}, Sync: ${SYNC_STATE}"
            exit 1
        else
            log "INFO" "Waiting for node to sync... (${i}s/${MAX_SYNC_WAIT}s)"
            sleep $WAIT_INTERVAL
        fi
    done
}

# Main execution
init
log "INFO" "Starting backup process"
desync_database
create_backup
enable_sync
log "INFO" "Backup completed successfully"
