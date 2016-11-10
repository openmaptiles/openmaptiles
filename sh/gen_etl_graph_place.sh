

DOT=place.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/place/mapping.yaml | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT

cat ./layers/place/types.sql   | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/city.sql    | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/country.sql | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/state.sql   | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/merge_country_rank.sql  | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/merge_city_rank.sql     | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/merge_state_rank.sql    | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/place/place.sql               | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_place_etl.png
