#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CSV="$DIR/checked_slugs.csv"

# Initialize CSV if it doesn't exist
if [ ! -f "$CSV" ]; then
    echo "slug,result" > "$CSV"
fi

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

# Check for --force option
force=0
if [ "$1" = "--force" ]; then
  force=1
fi

# Function to remove instances of more than 5 <strong> tags in a row
remove_excessive_strong_tags() {
    echo "$1" | sed ':a;N;$!ba;s/<strong>\(<strong>\)\{4,\}//g' | sed ':a;N;$!ba;s/<\/strong>\(<\/strong>\)\{4,\}//g'
}

total_slugs=$(echo $slugs | wc -w | tr -d ' ')
counter=0

for slug in $slugs
do
    if [ -z "$slug" ]
    then
        echo "empty slug"
        continue
    fi
    
    # Check if slug was previously checked and identical
    if [ $force -eq 0 ]; then
        if grep -q "$slug" "$CSV"; then
            echo "Skipping $slug, previously checked. use --force to check again."
            ((counter++))
            continue
        fi
    fi

    prod="https://$PROD_PUBLIC_DOMAIN/$slug"
    local="http://$LOCAL_PUBLIC_DOMAIN:9001/$slug"

    # fetch the data from the URLs
    data1=$(curl --max-time 10 -s $prod) || data1='prodfail'
    data2=$(curl --max-time 10 -s $local) || data2='localfail'

    # Extract the <body> section
    data1_body=$(echo "$data1" | sed -n '/<body>/,/<\/body>/p')
    data2_body=$(echo "$data2" | sed -n '/<body>/,/<\/body>/p')
    
    # Preprocess to remove 'class="footnote"' from <a> tags
    data1_preprocessed=$(echo "$data1_body" | sed 's/<a class="footnote" id="/<a id="/g')
    data2_preprocessed=$(echo "$data2_body" | sed 's/<a class="footnote" id="/<a id="/g')

    # Additional preprocessing to remove instances of more than 5 <strong> tags in a row
    data1_preprocessed=$(remove_excessive_strong_tags "$data1_preprocessed")
    data2_preprocessed=$(remove_excessive_strong_tags "$data2_preprocessed")

    # Format the <body> section without fixing errors
    data1_formatted=$(echo "$data1_preprocessed" | tidy -q -indent --show-errors 0 --show-warnings no 2>/dev/null)
    data2_formatted=$(echo "$data2_preprocessed" | tidy -q -indent --show-errors 0 --show-warnings no 2>/dev/null)

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

    # Compare the formatted <body> content
    if [ "$data1_formatted" == "$data2_formatted" ]
    then
        echo "✅ $padded $progress\t    Identical"
        echo "$slug,identical" >> "$CSV"
    else
        echo "❌ $padded $progress\t    Different"
        echo "$slug,different" >> "$CSV"
        echo "$data1_formatted" > $DIR/html/$slug.prod.txt
        echo "$data2_formatted" > $DIR/html/$slug.local.txt
        diff $DIR/html/$slug.prod.txt $DIR/html/$slug.local.txt > $DIR/html/$slug.diff.txt
        code -d $DIR/html/$slug.prod.txt $DIR/html/$slug.local.txt
        sleep 0.5
        read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Move to a new line
    fi
done