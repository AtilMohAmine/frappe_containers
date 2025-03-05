#!/bin/bash

# Script to create a backup and maintain a limit of 4 backups
# Usage: ./manage-backups.sh site_name [--with-files]

# Parameters
SITE_NAME=$1
WITH_FILES=$2

# Ensure site name is provided
if [ -z "$SITE_NAME" ]; then
  echo "Error: Site name is required"
  exit 1
fi

# Full site name
FULL_SITE_NAME="${SITE_NAME}.waves-skipper.com"
BACKUP_DIR="/home/frappe/frappe-bench/sites/${FULL_SITE_NAME}/private/backups"

# Create backup
echo "Creating backup for ${FULL_SITE_NAME}..."
bench --site ${FULL_SITE_NAME} backup ${WITH_FILES}

# Get all unique backup prefixes by examining database backups
# Format: YYYYMMDD_HHMMSS-site_name_waves_skipper_com
echo "Checking for existing backups..."
BACKUP_PREFIXES=$(ls -t ${BACKUP_DIR}/*-database.sql.gz | sed -E 's/(.*)(-database\.sql\.gz)/\1/' | sort -r)

# Convert to array
readarray -t PREFIXES <<< "$BACKUP_PREFIXES"

# Count backups
BACKUP_COUNT=${#PREFIXES[@]}
echo "Found ${BACKUP_COUNT} backups"

# If we have more than 4 backups, remove oldest ones
if [ $BACKUP_COUNT -gt 4 ]; then
  # Calculate how many to remove
  REMOVE_COUNT=$((BACKUP_COUNT - 4))
  echo "Will remove ${REMOVE_COUNT} oldest backups"
  
  # Get the oldest backups to remove (last entries in the sorted array)
  for ((i=BACKUP_COUNT-1; i>=BACKUP_COUNT-REMOVE_COUNT; i--)); do
    PREFIX="${PREFIXES[i]}"
    
    echo "Removing backup with prefix: ${PREFIX}"
    
    # Remove all files with this prefix
    rm -f ${PREFIX}-site_config_backup.json
    rm -f ${PREFIX}-database.sql.gz
    rm -f ${PREFIX}-files.tar
    rm -f ${PREFIX}-private-files.tar
    
    echo "Removed backup: ${PREFIX}"
  done
fi

# List remaining backups
echo "Current backups after cleanup:"
ls -la ${BACKUP_DIR}/*-database.sql.gz

echo "Backup management completed successfully."
exit 0
