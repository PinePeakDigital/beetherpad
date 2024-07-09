#!/bin/sh

# USAGE:
# PGPASSWORD=the_password DB_HOST=the_host DB_PORT=the_port DB_USER=the_user DB_NAME=the_name ./scripts/push-postgres.sh
# or use .env to set them

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/../.env"
if [ -f "$ENV" ]; then
  source "$ENV"
fi

export PGPASSWORD

DUMP_FILE="dump-postgres.sql"

read -p "This will delete the existing contents of the database. Are you sure you want to continue? (y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborting."
    exit 1
fi

# Delete the contents of the target database
echo "DROP SCHEMA IF EXISTS etherpad CASCADE; DROP TABLE IF EXISTS store CASCADE;" | psql -h $DB_HOST -U $DB_USER -d $DB_NAME

# Check the format of the dump file
if file $DUMP_FILE | grep -q "PostgreSQL custom database dump"; then
        # Use pg_restore for custom or tar file formats
        pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $DUMP_FILE
else
        # Use psql for plain-text files
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $DUMP_FILE
fi