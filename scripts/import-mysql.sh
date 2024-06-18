#!/bin/sh
# Database migration from MySQL to Render.com Postgres

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/../.env"
if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

retry() {
  local retries=3
  local wait=3

  for i in $(seq 1 $retries); do
    "$@" && return $?
    echo "Command failed... retry attempt $i"
    sleep $wait
  done
}

THRESHOLD_GIGS=24
THRESHOLD_KB=$(($THRESHOLD_GIGS * 1024 * 1024))
PATH_TO_CHECK="/"
FREE_SPACE=$(df -P $PATH_TO_CHECK | awk 'NR==2 {print $4}')

if [ $FREE_SPACE -lt $THRESHOLD_KB ]; then
  echo "Not enough free space on $PATH_TO_CHECK"
  df -h $PATH_TO_CHECK
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/../.env"

if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

DATE_STRING=$(date +%Y-%m-%d-%H-%M-%S)
# MYSQL_FILENAME=$DIR/../dump-mysql-$DATE_STRING.sql
MYSQL_FILENAME=$DIR/../dump-mysql.sql
POSTGRES_FILENAME=$DIR/../dump-postgres-$DATE_STRING.sql
MYSQL_CONTAINER_NAME=beetherpad-mysql-transfer
POSTGRES_CONTAINER_NAME=beetherpad-postgres-transfer

# WARNING: Causes etherpad downtime
# echo dump the MySQL database
# ssh root@$PROD_SECRET_DOMAIN 'mysqldump -u etherpad -p etherpad' > $MYSQL_FILENAME

echo start a local MySQL container
if [ $(docker ps -q -f name=$MYSQL_CONTAINER_NAME) ]; then
    echo "Container $MYSQL_CONTAINER_NAME is running"
elif [ $(docker ps -a -q -f name=$MYSQL_CONTAINER_NAME) ]; then
    echo "Container $MYSQL_CONTAINER_NAME exists but is not running, starting it up"
    docker start $MYSQL_CONTAINER_NAME
else
    echo "Container does not exist, creating and starting"
    docker run --rm -d --name $MYSQL_CONTAINER_NAME \
      -e MYSQL_ROOT_PASSWORD=root \
      -e MYSQL_DATABASE=etherpad \
      -e MYSQL_USER=etherpad \
      -e MYSQL_PASSWORD=etherpad \
      -e MYSQLD_DEFAULT_AUTHENTICATION_PLUGIN=mysql_native_password \
      -p 3306:3306 \
      mysql:5.7
fi
MYSQL_ID=$(docker ps -q -f name=$MYSQL_CONTAINER_NAME)

echo "Wait for MySQL to start"
start=`date +%s`
while ! docker exec $MYSQL_ID mysql -u root -proot -e "SELECT 1" > /dev/null 2>&1; do
    sleep 1
    end=`date +%s`
    runtime=$((end-start))
    printf "Waiting... Time elapsed: %s seconds\r" $runtime
done
echo "\nMySQL started"

echo "Check if database has been populated"
COUNT=$(docker exec $MYSQL_ID mysql -u root -proot -e "USE etherpad; SELECT COUNT(*) FROM store;" | tail -n1)

if [ $COUNT -gt 1000 ]; then
    echo "Database already populated"
else
    echo "Database not populated"

    echo further configure the MySQL container
    retry docker exec $MYSQL_ID mysql -u root -proot <<SQL
        SET GLOBAL max_allowed_packet=1073741824;
        SET GLOBAL wait_timeout=28800;
        ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
        FLUSH PRIVILEGES;
SQL

    echo import the MySQL dump into the local MySQL container
    docker exec -i $MYSQL_ID mysql -u root -proot etherpad < $MYSQL_FILENAME
fi

echo spin up the etherpad postgres container
if [ $(docker ps -q -f name=$POSTGRES_CONTAINER_NAME) ]; then
    echo "Container $POSTGRES_CONTAINER_NAME is running"
elif [ $(docker ps -a -q -f name=$POSTGRES_CONTAINER_NAME) ]; then
    echo "Container $POSTGRES_CONTAINER_NAME exists but is not running, starting it up"
    docker start $POSTGRES_CONTAINER_NAME
else
    echo "Container does not exist, creating and starting"
    docker-compose run --service-ports --detach --name $POSTGRES_CONTAINER_NAME postgres
fi
POSTGRES_ID=$(docker ps -q -f name=$POSTGRES_CONTAINER_NAME)

echo create the etherpad database in the postgres container
# connect to postgres database since we can't drop a database
# that we are currently connected to
psql -v ON_ERROR_STOP=1 -U etherpad -d postgres <<SQL
    DROP DATABASE IF EXISTS etherpad;
    CREATE DATABASE etherpad;
SQL

echo import the MySQL dump into the postgres container
pgloader --with "prefetch rows = 10000" \
  mysql://etherpad:etherpad@localhost/etherpad \
  postgresql://etherpad@localhost/etherpad

echo dump the postgres database
docker run --net host --rm -i postgres:16.2 \
  pg_dump -h 127.0.0.1 -U etherpad -d etherpad \
  > $POSTGRES_FILENAME

echo stop containers
docker stop $MYSQL_ID
docker stop $POSTGRES_ID

echo done
osascript -e 'beep 3'