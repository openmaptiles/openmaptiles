#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

layerid=$1
classvars=$2

echo "# FREQ - $layerid  group by : $classvars "

for z in {0..15}
do
echo " "
echo "## $layerid z$z  - freq"

: "${TOOLS_VERSION:=$(cat "$(dirname "$0")/../TOOLS_VERSION")}"
SQL=$(docker run --rm -v "$(pwd):/tileset" "openmaptiles/openmaptiles-tools:$TOOLS_VERSION" generate-sqlquery  layers/${layerid}/${layerid}.yaml $z )

SQLCODE=$(cat <<-END
select $classvars , count(*) as _count_ from
( $SQL ) as t
GROUP BY $classvars
ORDER BY $classvars
;
END
)

#echo "\`\`\`sql"
#echo "$SQLCODE"
#echo "\`\`\`"

docker-compose run --rm import-osm /usr/src/app/psql.sh -q -P pager=off -P border=2 -P footer=off -P null='(null)' -c "$SQLCODE" \
   | sed '1d;$d'  | sed '$d' | sed 's/+--/|--/g' | sed 's/--+/--|/g'

done

