



DOT=building.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/building/mapping.yaml    | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
cat ./layers/building/building.sql    | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_building_etl.png
