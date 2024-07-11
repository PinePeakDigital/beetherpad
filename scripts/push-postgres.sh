#!/bin/sh

# USAGE:
# PGPASSWORD=the_password DB_HOST=the_host DB_USER=the_user DB_NAME=the_name ./scripts/push-postgres.sh
# or use .env to set them

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/../.env"
if [ -f "$ENV" ]; then
  source "$ENV"
fi

export PGPASSWORD
export PGOPTIONS='-c on_error_stop=on'

DUMP_FILE="dump-postgres.sql"
# DUMP_FILE="minidump.sql"

read -p "This will delete the existing contents of the database. Are you sure you want to continue? (y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborting."
    exit 1
fi

# Check if the dump file exists
if [ ! -f $DUMP_FILE ]; then
        echo "Dump file not found: $DUMP_FILE"
        exit 1
fi

# Check if PGPASSWORD is set
if [ -z $PGPASSWORD ]; then
        echo "PGPASSWORD is not set"
        exit 1
fi

# Check if DB_HOST is set
if [ -z $DB_HOST ]; then
        echo "DB_HOST is not set"
        exit 1
fi

# Check if DB_USER is set
if [ -z $DB_USER ]; then
        echo "DB_USER is not set"
        exit 1
fi

# Check if DB_NAME is set
if [ -z $DB_NAME ]; then
        echo "DB_NAME is not set"
        exit 1
fi

echo "Preparing database..."
PREP_SQL="DROP SCHEMA IF EXISTS $DB_NAME CASCADE; \
DROP TABLE IF EXISTS store CASCADE; \
CREATE ROLE etherpad; \
GRANT ALL ON SCHEMA public TO etherpad; \
GRANT etherpad TO $DB_USER;"

# Connect to postgres instead of DB_NAME since we can't drop
# the database we're connected to
echo "$PREP_SQL" | psql -h $DB_HOST -U $DB_USER -d postgres

echo "Restoring database from dump file..."
if file $DUMP_FILE | grep -q "PostgreSQL custom database dump"; then
        # Use pg_restore for custom or tar file formats
        echo "Using pg_restore..."
        pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME -c $DUMP_FILE
else
        # Use psql for plain-text files
        echo "Using psql..."
        psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f $DUMP_FILE
fi

echo "Done"