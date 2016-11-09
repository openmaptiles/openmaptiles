

DOT=highway_name.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/highway_name/layer.sql          | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/highway_name/merge_highways.sql | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT 

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_highway_names_etl.png
