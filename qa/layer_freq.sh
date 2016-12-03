
#!/bin/bash

layerid=$1
classvars=$2

echo "# FREQ - $layerid  group by : $classvars "

for z in {0..15}
do
echo " "
echo "## $layerid z$z  - freq" 

SQL=$(generate-qadoc  layers/${layerid}/${layerid}.yaml $z ) 

read -r -d '' SQLCODE <<- EOMSQL
  select $classvars , count(*) as _count_ from
  $SQL 
  GROUP BY $classvars
  ORDER BY $classvars
  ;
EOMSQL

#echo "\`\`\`SQL"
#echo "$SQLCODE"
#echo "\`\`\`"

docker-compose run --rm import-osm /usr/src/app/psql.sh -q -P pager=off -P border=2 -P footer=off -P null='(null)' -c "$SQLCODE" \
   | sed '1d;$d'  | sed '$d' | sed 's/+--/|--/g' | sed 's/--+/--|/g' 
     
done

