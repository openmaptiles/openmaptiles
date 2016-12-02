
#!/bin/bash

layerid=$1
var=$2

echo "# NUMVAR-ANALYZE - $layerid  - $var "

for z in {0..15}
do
echo " "
echo "## $layerid z$z - $var "

SQL=$(generate-qadoc  layers/${layerid}/${layerid}.yaml $z ) 

read -r -d '' SQLCODE <<- EOMSQL
  SELECT 
    count($var)    as count_$var
   ,min($var)      as min_$var      
   ,max($var)      as max_$var 
   ,avg($var)      as avg_$var 
   ,stddev($var)   as stddev_$var 
   ,variance($var) as variance_$var 
  FROM  
   $SQL 
  ;
EOMSQL

echo "\`\`\`SQL"
echo "$SQLCODE"
echo "\`\`\`"

docker-compose run --rm import-osm /usr/src/app/psql.sh -q -P pager=off -P border=2 -P footer=off -P null='(null)' -c "$SQLCODE" \
   | sed '1d;$d'  | sed '$d' | sed 's/+--/|--/g' | sed 's/--+/--|/g' 
     
done

