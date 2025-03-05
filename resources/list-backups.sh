#!/bin/bash

# Script to list all backups for a site with details
# Usage: ./list-backups.sh site_name

# Parameters
SITE_NAME=$1

# Ensure site name is provided
if [ -z "$SITE_NAME" ]; then
  echo "Error: Site name is required"
  exit 1
fi

# Full site name
FULL_SITE_NAME="${SITE_NAME}.waves-skipper.com"
BACKUP_DIR="/home/frappe/frappe-bench/sites/${FULL_SITE_NAME}/private/backups"

# Exit if backup directory doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo "[]"
    exit 0
fi

# Get all database backups (they should always exist)
DB_BACKUPS=$(ls -t $BACKUP_DIR/*-database.sql.gz 2>/dev/null || echo "")

if [ -z "$DB_BACKUPS" ]; then
    echo "[]"
    exit 0
fi

# Start JSON array
echo "["

first=true

for DB_FILE in $DB_BACKUPS; do
    if [ "$first" = true ]; then
        first=false
    else
        echo ","
    fi
    
    # Extract prefix and filename parts
    PREFIX=$(echo $DB_FILE | sed -E 's/(.*)(-database\.sql\.gz)/\1/')
    FILENAME=$(basename $DB_FILE)
    BASE_NAME=$(echo $FILENAME | sed -E 's/(.*)(-database\.sql\.gz)/\1/')
    
    # Extract date from filename (format: YYYYMMDD_HHMMSS)
    DATE_PART=$(echo $BASE_NAME | cut -d'-' -f1)
    YEAR=${DATE_PART:0:4}
    MONTH=${DATE_PART:4:2}
    DAY=${DATE_PART:6:2}
    HOUR=${DATE_PART:9:2}
    MINUTE=${DATE_PART:11:2}
    SECOND=${DATE_PART:13:2}
    FORMATTED_DATE="$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND"
    
    # Check file existence
    CONFIG_FILE="$PREFIX-site_config_backup.json"
    PUBLIC_FILE="$PREFIX-files.tar"
    PRIVATE_FILE="$PREFIX-private-files.tar"
    
    # Get file sizes
    DB_SIZE=$(ls -lh $DB_FILE | awk '{print $5}')
    CONFIG_SIZE=$(ls -lh $CONFIG_FILE 2>/dev/null | awk '{print $5}' || echo "N/A")
    
    # Determine backup type
    if [ -f "$PUBLIC_FILE" ] && [ -f "$PRIVATE_FILE" ]; then
        BACKUP_TYPE="Full"
        PUBLIC_SIZE=$(ls -lh $PUBLIC_FILE | awk '{print $5}')
        PRIVATE_SIZE=$(ls -lh $PRIVATE_FILE | awk '{print $5}')
        TOTAL_SIZE="DB: $DB_SIZE, Config: $CONFIG_SIZE, Public: $PUBLIC_SIZE, Private: $PRIVATE_SIZE"
    else
        BACKUP_TYPE="Database only"
        TOTAL_SIZE="DB: $DB_SIZE, Config: $CONFIG_SIZE"
    fi
    
    # Output JSON object for this backup
    cat << EOF
    {
        "id": "$BASE_NAME",
        "date": "$FORMATTED_DATE",
        "type": "$BACKUP_TYPE",
        "size": "$TOTAL_SIZE",
        "status": "Available",
        "files": {
            "database": "$FILENAME",
            "config": "$(basename $CONFIG_FILE)",
            "public": "$([ -f "$PUBLIC_FILE" ] && basename $PUBLIC_FILE || echo "")",
            "private": "$([ -f "$PRIVATE_FILE" ] && basename $PRIVATE_FILE || echo "")"
        }
    }
EOF
done

# End JSON array
echo "]"