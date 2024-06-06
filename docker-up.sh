#!/bin/sh

CACHE_DIR=${CACHE_DIR:=$HOME/.cache}
if [ "$(uname)" = "Darwin" ]; then
    CACHE_DIR=${CACHE_DIR:=$HOME/Library/Caches}
fi
DEV_ENV=${DEV_ENV:-false}

if [ -z "${ETHERPAD_SECRET_DOMAIN}" ]; then
    echo "Secret domain isn't set! Set ETHERPAD_SECRET_DOMAIN."
    exit 1
fi
ETHERPAD_VERSION='2.0.3'
ETHERPAD_PLUGINS="\
ep_adminpads3 \
ep_author_hover \
ep_brightcolorpicker \
ep_pad_activity_nofication_in_title \
ep_prompt_for_name \
ep_sync_status"
ETHERPAD_LOCAL_PLUGINS="ep_simple_urls ep_post_data"

# Build Phase
etherpad_path="$CACHE_DIR/etherpad-lite"
etherpad_plugin_path="$etherpad_path/src/local_plugins"

if [ ! -d "$etherpad_path" ]; then
    git clone --branch "$ETHERPAD_VERSION" --depth 1 \
        'https://github.com/ether/etherpad-lite.git' "$etherpad_path"
else
    old_dir="$PWD"
    cd "$etherpad_path" || exit
    git reset --hard HEAD
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

cp "$PWD/settings.json" "$etherpad_path/settings.json.docker"

docker_build() {
    if [ "$DEV_ENV" = "true" ]; then
        set -- --build-arg=EP_UID=0
    fi

    docker build -t beetherpad \
        --build-arg=ETHERPAD_PLUGINS="$ETHERPAD_PLUGINS" \
        --build-arg=ETHERPAD_LOCAL_PLUGINS="$etherpad_local_plugins_buildarg" \
        "$@" \
        "$etherpad_path"
}

docker_build

if [ "$DEV_ENV" = "true" ]; then
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

    until [ "$(docker container inspect -f '{{.State.Status}}' postgres)" = "running" ]; do
        printf "%s\r" "Waiting for postgres..."
        sleep 2
    done
fi

docker_run() {
    docker container rm beetherpad

    if [ "$DEV_ENV" = "true" ]; then
        set -- --network=beetherpad-network
        for plugin in $ETHERPAD_LOCAL_PLUGINS; do
            set -- --mount "type=bind,source=$(pwd)/${plugin},target=/opt/etherpad-lite/node_modules/ep_etherpad-lite/node_modules/${plugin}" "$@"
        done
    fi

    docker run --name beetherpad \
        --restart always \
        --detach \
        --env DB_TYPE=postgres \
        --env DB_HOST="${DB_HOST:-postgres}" \
        --env DB_PORT="${DB_PORT:-5432}" \
        --env DB_NAME="${DB_NAME:-etherpad}" \
        --env DB_USER="${DB_USER:-etherpad}" \
        --env DB_PASS="${DB_PASS:-secretpassword}" \
        --env ETHERPAD_SECRET_DOMAIN="${ETHERPAD_SECRET_DOMAIN}" \
        --publish 9001:9001 \
        "$@" \
        beetherpad
}

docker_run
