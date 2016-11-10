

DOT=housenumber.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/housenumber/mapping.yaml              | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
cat ./layers/housenumber/housenumber_centroid.sql  | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/housenumber/layer.sql                 | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT 

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_housenumber_etl.png
