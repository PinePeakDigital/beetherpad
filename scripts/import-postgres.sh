#!/bin/sh

CONTAINER_NAME="postgres"
DUMP_FILE="dump-postgres.sql"
DB_USER="etherpad"
DB_NAME="etherpad"

# Check the format of the dump file
if file $DUMP_FILE | grep -q "PostgreSQL custom database dump"; then
    # Use pg_restore for custom or tar file formats
    cat $DUMP_FILE | docker exec -i $CONTAINER_NAME pg_restore -U $DB_USER -d $DB_NAME
else
    # Use psql for plain-text files
    cat $DUMP_FILE | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME
fi