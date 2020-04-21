#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

layerid=$1
classvar=$2

for z in {0..15}
do
echo " "
echo "## $layerid z$z   max length ($classvar)"

SQL=$(docker-compose run --rm openmaptiles-tools generate-sqlquery  layers/${layerid}/${layerid}.yaml $z )

SQLCODE=$(cat <<-END
SELECT DISTINCT $classvar , length( $classvar ) AS _length_ from
( $SQL ) as t
WHERE length( $classvar ) > 0
ORDER BY length( $classvar ) DESC NULLS LAST
LIMIT 30
;
END
)

#echo "\`\`\`sql"
#echo "$SQLCODE"
#echo "\`\`\`"

docker-compose run --rm import-osm /usr/src/app/psql.sh -q -P pager=off -P border=2 -P footer=off -P null='(null)' -c "$SQLCODE" \
   | sed '1d;$d'  | sed '$d' | sed 's/+--/|--/g' | sed 's/--+/--|/g'

done

