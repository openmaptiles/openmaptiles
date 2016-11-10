

DOT=landcover.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/landcover/mapping.yaml   | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
cat ./layers/landcover/landcover.sql  | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_landcover_etl.png
