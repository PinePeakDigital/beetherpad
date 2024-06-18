#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/.env"
if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

CACHE_DIR=${CACHE_DIR:=$HOME/.cache}
if [ "$(uname)" = "Darwin" ]; then
    CACHE_DIR=${CACHE_DIR:=$HOME/Library/Caches}
fi
DEV_ENV=${DEV_ENV:-false}
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-etherpad}"
DB_USER="${DB_USER:-etherpad}"
DB_PASS="${DB_PASS:-secretpassword}"

if [ "$DEV_ENV" = "true" ]; then
    ETHERPAD_SECRET_DOMAIN=$LOCAL_SECRET_DOMAIN
else
    ETHERPAD_SECRET_DOMAIN=$PROD_SECRET_DOMAIN
fi

if [ -z "${ETHERPAD_SECRET_DOMAIN}" ]; then
    echo "Secret domain isn't set! Ensure DEV_ENV, LOCAL_SECRET_DOMAIN, & PROD_SECRET_DOMAIN are properly defined."
    exit 1
fi

# Docker resource names
DOCKER_NETWORK_NAME="beetherpad-network"
DOCKER_POSTGRES_NAME="beetherpad-postgres"
DOCKER_POSTGRES_VOLUME_NAME="beetherpad-postgres-data"
DOCKER_IMAGE_NAME="beetherpad"
DOCKER_CONTAINER_NAME="beetherpad"
DB_HOST="${DB_HOST:-$DOCKER_POSTGRES_NAME}"

ETHERPAD_VERSION='bc1032a9d00caae8f34d6cfc11c8733c21fff0f1'
ETHERPAD_PLUGINS="\
ep_author_hover \
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
    git fetch origin "$ETHERPAD_VERSION"
    git checkout "$ETHERPAD_VERSION"
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

# Invoke like has_docker container beetherpad || docker run ...
has_docker() {
    type=$1
    name=$2

    docker "$1" inspect "$2" > /dev/null 2>&1
}

docker_build() {
    if [ "$DEV_ENV" = "true" ]; then
        set -- --build-arg=EP_UID=0
    fi

    docker build -t $DOCKER_IMAGE_NAME \
        --build-arg=ETHERPAD_PLUGINS="$ETHERPAD_PLUGINS" \
        --build-arg=ETHERPAD_LOCAL_PLUGINS="$etherpad_local_plugins_buildarg" \
        "$@" \
        "$etherpad_path"
}

docker_build

if [ "$DEV_ENV" = "true" ]; then
    # Environment Setup
    has_docker volume $DOCKER_POSTGRES_VOLUME_NAME || \
        docker volume create $DOCKER_POSTGRES_VOLUME_NAME
    has_docker network $DOCKER_NETWORK_NAME || \
        docker network create --driver bridge $DOCKER_NETWORK_NAME

    has_docker container $DOCKER_POSTGRES_NAME && \
        docker container rm $DOCKER_POSTGRES_NAME

    # Run containers
    docker run \
        --name $DOCKER_POSTGRES_NAME \
        --restart always \
        --detach \
        --network=$DOCKER_NETWORK_NAME \
        --env POSTGRES_DB="${DB_NAME}" \
        --env PGPORT="${DB_PORT}" \
        --env POSTGRES_USER="${DB_USER}" \
        --env POSTGRES_PASSWORD="${DB_PASS}" \
        --volume $DOCKER_POSTGRES_VOLUME_NAME:/var/lib/postgresql/data \
        --publish "${DB_PORT}:${DB_PORT}" \
        postgres:latest

    until [ "$(docker container inspect -f '{{.State.Status}}' $DOCKER_POSTGRES_NAME)" = "running" ]; do
        printf "%s\r" "Waiting for $DOCKER_POSTGRES_NAME..."
        sleep 2
    done
fi

docker_run() {
    has_docker container $DOCKER_IMAGE_NAME && \
        docker container rm $DOCKER_IMAGE_NAME
    
    if [ "$DEV_ENV" = "true" ]; then
        set -- --network=$DOCKER_NETWORK_NAME
        for plugin in $ETHERPAD_LOCAL_PLUGINS; do
            set -- \
                --mount "type=bind,source=$(pwd)/${plugin},target=/opt/etherpad-lite/node_modules/ep_etherpad-lite/node_modules/${plugin}" \
                --mount "type=volume,source=empty_volume_${plugin},target=/opt/etherpad-lite/node_modules/ep_etherpad-lite/node_modules/${plugin}/node_modules" \
                "$@"
        done
    fi

    docker run --name $DOCKER_CONTAINER_NAME \
        --restart always \
        --detach \
        --env DB_TYPE=postgres \
        --env DB_HOST="${DB_HOST}" \
        --env DB_PORT="${DB_PORT}" \
        --env DB_NAME="${DB_NAME}" \
        --env DB_USER="${DB_USER}" \
        --env DB_PASS="${DB_PASS}" \
        --env ETHERPAD_SECRET_DOMAIN="${ETHERPAD_SECRET_DOMAIN}" \
        --publish 9001:9001 \
        "$@" \
        $DOCKER_IMAGE_NAME
}

docker_run

until [ "$(docker container inspect -f '{{.State.Health.Status}}' $DOCKER_CONTAINER_NAME)" = "healthy" ]; do
    printf "%s\r" "Waiting for $DOCKER_CONTAINER_NAME..."
    sleep 1
done
