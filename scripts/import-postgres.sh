#!/bin/sh

CONTAINER_NAME="beetherpad-postgres"
DUMP_FILE="dump-postgres.sql"
DB_USER="etherpad"
DB_NAME="etherpad"

# Ask for confirmation
read -p "This will delete the existing contents of the database. Are you sure you want to continue? (y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Aborting."
  exit 1
fi

# Check if there's enough storage available
dump_size=$(du -s $DUMP_FILE | cut -f1)
available_space=$(df / | tail -1 | awk '{print $4}')
if [ $dump_size -gt $available_space ]; then
  echo "Not enough storage available for the import. Aborting."
  exit 1
fi

# Delete the contents of the target database
echo "DROP SCHEMA IF EXISTS etherpad CASCADE; DROP TABLE IF EXISTS store CASCADE;" | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME

# Check the format of the dump file
if file $DUMP_FILE | grep -q "PostgreSQL custom database dump"; then
    # Use pg_restore for custom or tar file formats
    cat $DUMP_FILE | docker exec -i $CONTAINER_NAME pg_restore -U $DB_USER -d $DB_NAME
else
    # Use psql for plain-text files
    cat $DUMP_FILE | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME
fi