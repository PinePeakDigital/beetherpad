#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/../.env"
if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

mkdir -p $DIR/html
slugs=$($DIR/padlist.sh | awk -F: '{split($2,a," "); print a[1]}')

longest_length=0
for slug in $slugs
do
    if [ ${#slug} -gt $longest_length ]
    then
        longest_length=${#slug}
    fi
done

total_slugs=$(echo $slugs | wc -w | tr -d ' ')
counter=0

for slug in $slugs
do
    if [ -z "$slug" ]
    then
        echo "empty slug"
        continue
    fi
    
    prod="https://$PROD_PUBLIC_DOMAIN/$slug"
    local="http://$LOCAL_PUBLIC_DOMAIN:9001/$slug"

    # fetch the data from the URLs
    data1=$(curl --max-time 10 -s $prod) || data1='prodfail'
    data2=$(curl --max-time 10 -s $local) || data2='localfail'

    padded=$(printf "%-${longest_length}s" "$slug")

    ((counter++))
    progress="$counter/$total_slugs"

    if [ "$data1" == "prodfail" ]
    then
        echo "🔥 $padded $progress\t    prodfail"
        continue
    fi

    if [ "$data2" == "localfail" ]
    then
        echo "🔥 $padded $progress\t    localfail"
        continue
    fi

    # compare the data
    if [ "$data1" == "$data2" ]
    then
        echo "✅ $padded $progress\t    Identical"
    else
        echo "❌ $padded $progress\t    Different"
        echo "$data1" > $DIR/html/$slug.prod.txt
        echo "$data2" > $DIR/html/$slug.local.txt
        diff $DIR/html/$slug.prod.txt $DIR/html/$slug.local.txt > $DIR/html/$slug.diff.txt
    fi
done
