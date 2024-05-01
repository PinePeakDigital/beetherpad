#!/bin/sh
# List all the slugs of all the pads, one per line.
# Could add "HAVING qty > 2" to the query to exclude never-touched pads.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV="$DIR/../.env"

if [ -f "$ENV" ]; then
  export $(cat $ENV | xargs)
fi

psql -q etherpad <<'SQL'
  \a
  \pset fieldsep '\t'
  \pset footer off
  select
    REGEXP_SUBSTR(store.key, '^pad(2readonly)?:[^:]+') as padname,
    count(1) as qty
    from store
    GROUP BY padname
    ORDER BY qty DESC;
SQL
