

DOT=landuse.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/landuse/mapping.yaml | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
cat ./layers/landuse/landuse.sql  | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_landuse_etl.png
