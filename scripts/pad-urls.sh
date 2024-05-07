#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ENV="$DIR/../.env"

if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

slugs=$($DIR/padlist.sh | awk -F: '{split($2,a," "); print a[1]}')

for slug in $slugs
do
    if [ -z "$slug" ]
    then
        echo "empty slug"
        continue
    fi
    
    echo "$SERVER_URL/$slug"
done