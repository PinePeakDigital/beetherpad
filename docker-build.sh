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

# Docker resource names
DOCKER_NETWORK_NAME="beetherpad-network"
DOCKER_POSTGRES_NAME="beetherpad-postgres"
DOCKER_POSTGRES_VOLUME_NAME="beetherpad-postgres-data"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-beetherpad}"
DOCKER_CONTAINER_NAME="beetherpad"
DB_HOST="${DB_HOST:-$DOCKER_POSTGRES_NAME}"

ETHERPAD_VERSION='bc1032a9d00caae8f34d6cfc11c8733c21fff0f1'
ETHERPAD_PLUGINS="\
ep_author_hover \
ep_pad_activity_nofication_in_title \
ep_prompt_for_name \
ep_sync_status"
ETHERPAD_LOCAL_PLUGINS="ep_simple_urls ep_post_data"

# Repo Setup
etherpad_path="$CACHE_DIR/etherpad-lite"
etherpad_plugin_path="$etherpad_path/src/local_plugins"

if [ ! -d "$etherpad_path" ]; then
    git clone --depth 1 \
        'https://github.com/ether/etherpad-lite.git' "$etherpad_path"
fi

old_dir="$PWD"
cd "$etherpad_path" || exit
git reset --hard HEAD
git clean -xdf
git fetch origin "$ETHERPAD_VERSION"
git checkout "$ETHERPAD_VERSION"
cd "$old_dir" || exit

mkdir -p "$etherpad_plugin_path"
cp "$PWD/settings.json" "$etherpad_path/settings.json.docker"

# Build Arg Setup
etherpad_local_plugins_buildarg=''
for plugin in $ETHERPAD_LOCAL_PLUGINS; do
    rm -rf "$etherpad_plugin_path/${plugin:?}"
    cp -r "$PWD/$plugin" "$etherpad_plugin_path/$plugin"
    etherpad_local_plugins_buildarg="$etherpad_local_plugins_buildarg ../src/local_plugins/$plugin"
done

if [ "$DEV_ENV" = "true" ]; then
    set -- --build-arg=EP_UID=0
fi

# Build
docker build -t $DOCKER_IMAGE_NAME \
    --build-arg=ETHERPAD_PLUGINS="$ETHERPAD_PLUGINS" \
    --build-arg=ETHERPAD_LOCAL_PLUGINS="$etherpad_local_plugins_buildarg" \
    "$@" \
    "$etherpad_path"