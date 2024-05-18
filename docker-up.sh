#!/bin/sh

user_home=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
CACHE_DIR=${CACHE_DIR:=$user_home/.cache}

ETHERPAD_VERSION='2.0.3'
ETHERPAD_PLUGINS="\
ep_adminpads3 \
ep_author_hover \
ep_brightcolorpicker \
ep_pad_activity_nofication_in_title \
ep_post_data ep_prompt_for_name \
ep_sync_status"
ETHERPAD_LOCAL_PLUGINS="ep_simple_urls"

# Build Phase
etherpad_path="$CACHE_DIR/etherpad-lite"
etherpad_plugin_path="$etherpad_path/src/local_plugins"

if [ ! -d "$etherpad_path" ]
  then git clone --branch "$ETHERPAD_VERSION" --depth 1 \
           'https://github.com/ether/etherpad-lite.git' "$etherpad_path"
else
    old_dir="$PWD"
    cd "$etherpad_path" || exit
    git clean -xdf
    git pull 'https://github.com/ether/etherpad-lite.git'
    cd "$old_dir" || exit
fi

mkdir -p "$etherpad_plugin_path"

etherpad_local_plugins_buildarg=''
for plugin in $ETHERPAD_LOCAL_PLUGINS; do
    rm -rf "$etherpad_plugin_path/${plugin:?}"
    cp -r "$PWD/$plugin" "$etherpad_plugin_path/$plugin"
    etherpad_local_plugins_buildarg="$etherpad_local_plugins_buildarg ../src/local_plugins/$plugin"
done

# If you're running this script with sudo, you probably don't want to
# leave root-owned files in your cache.
chown -R "${SUDO_USER:-$USER}:" "$etherpad_path"

docker build -t beetherpad \
       --build-arg=ETHERPAD_PLUGINS="$ETHERPAD_PLUGINS" \
       --build-arg=ETHERPAD_LOCAL_PLUGINS="$etherpad_local_plugins_buildarg" \
       "$etherpad_path"

# Environment Setup
docker volume create postgres-data
docker network create --driver bridge beetherpad-network

# Run containers
docker start postgres || docker run \
       --name postgres \
       --restart always \
       --detach \
       --network=beetherpad-network \
       --env POSTGRES_USER=etherpad \
       --env POSTGRES_PASSWORD=secretpassword \
       --env POSTGRES_DB=etherpad \
       --volume postgres-data:/var/lib/postgresql/data \
       --publish 5432:5432 \
       postgres:latest

until [ "$( docker container inspect -f '{{.State.Status}}' postgres )" = "running" ]; do
    printf "%s\r" "Waiting for postgres..."
    sleep 2
done

docker container rm beetherpad
docker run \
       --name beetherpad \
       --restart always \
       --detach \
       --env DB_TYPE=postgres \
       --env DB_HOST=postgres \
       --env DB_PORT=5432 \
       --env DB_NAME=etherpad \
       --env DB_USER=etherpad \
       --env DB_PASS=secretpassword \
       --env ADMIN_PASSWORD=secretpassword \
       --env IMPORT_EXPORT_MAX_REQ_PER_IP=1000 \
       --env PAD_OPTIONS_USER_MONOSPACE_FONT=true \
       --env PAD_SHORTCUTS_ENABLED_CMD_5=false \
       --network=beetherpad-network \
       --publish 9001:9001 \
       beetherpad
