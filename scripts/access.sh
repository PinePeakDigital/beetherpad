#!/bin/sh

dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ENV="$dir/../.env"
if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

editor_regex="Feature-Policy: sync-xhr 'self'"

fetch_post() {
    if [ "$DEV_ENV" = "true" ]; then
        url="http://$1:9001/$2"
    else
        url="https://$1/$2"
    fi

    curl -sLI "$url"
}

echo "Sanity checking..."

if ! fetch_post "$LOCAL_SECRET_DOMAIN" "expost" | grep -q "$editor_regex"; then
    echo "Can't detect editor app on secret domain!"
    exit
fi

echo "Fetching slugs..."
slugs=$("$dir"/padlist.sh | awk 'NR>1 { split($1, slug, ":"); print slug[2]; }' | sort -u)
count=$(echo "$slugs" | wc -w)

checked=0
printf "\33[2KChecked %d/%d\r" $checked "$count"

for slug in $slugs; do
    if fetch_post "$LOCAL_PUBLIC_DOMAIN" "$slug" | grep -q "$editor_regex"; then
        echo "Editor for $slug is publicly accessible!"
        exit 1
    fi

    checked=$((checked + 1))
    printf "\33[2KChecked %d/%d: %s\r" $checked "$count" "$slug"
done

printf "\n%s" "All clear!"
