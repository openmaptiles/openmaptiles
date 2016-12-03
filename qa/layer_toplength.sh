
#!/bin/bash


layerid=$1
classvar=$2

echo "# TOP30LENGHT - $layerid - $classvar"

for z in {0..15}
do
echo " "
echo "## $layerid z$z   max length ($classvar)"

SQL=$(generate-qadoc  layers/${layerid}/${layerid}.yaml $z ) 

read -r -d '' SQLCODE <<- EOMSQL
  select $classvar , length( $classvar ) as _length_ from
  $SQL 
  WHERE length( $classvar ) > 0
  ORDER BY length( $classvar )  DESC NULLS LAST
  LIMIT 30
  ;
EOMSQL

#echo "\`\`\`SQL"
#echo "$SQLCODE"
#echo "\`\`\`"

docker-compose run --rm import-osm /usr/src/app/psql.sh -q -P pager=off -P border=2 -P footer=off -P null='(null)' -c "$SQLCODE" \
   | sed '1d;$d'  | sed '$d' | sed 's/+--/|--/g' | sed 's/--+/--|/g' 
   
done

