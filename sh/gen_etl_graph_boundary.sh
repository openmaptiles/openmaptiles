



DOT=boundary.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/boundary/mapping.yaml   | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
cat ./layers/boundary/boundary.sql    | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_boundary_etl.png
