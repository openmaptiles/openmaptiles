

DOT=highway.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/highway/mapping.yaml        | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
cat ./layers/highway/types.sql           | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/highway/ne_global_roads.sql | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT 
cat ./layers/highway/highway.sql         | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_highway_etl.png
