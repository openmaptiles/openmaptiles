
#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

layerid=$1
var=$2

echo "# NUMVAR-ANALYZE - $layerid  - $var "

for z in {0..15}
do
echo " "
echo "## $layerid z$z - $var "

SQL=$(generate-sqlquery  layers/${layerid}/${layerid}.yaml $z ) 

read -r -d '' SQLCODE <<- EOMSQL
  SELECT 
    count($var)    as count
   ,min($var)      as min      
   ,max($var)      as max 
   ,avg($var)      as avg 
   ,stddev($var)   as stddev 
   ,variance($var) as variance 
  FROM  
   $SQL 
  ;
EOMSQL

#echo "\`\`\`SQL"
#echo "$SQLCODE"
#echo "\`\`\`"

docker-compose run --rm import-osm /usr/src/app/psql.sh -q -P pager=off -P border=2 -P footer=off -P null='(null)' -c "$SQLCODE" \
   | sed '1d;$d'  | sed '$d' | sed 's/+--/|--/g' | sed 's/--+/--|/g' 
     
done
