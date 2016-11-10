

ID=water_name
DOT=${ID}.dot

echo "digraph G
{    
rankdir=LR;
" > $DOT

cat ./layers/${ID}/merge_lakelines.sql  | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
cat ./layers/${ID}/layer.sql            | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT

echo "
}
" >> $DOT

cat $DOT

dot -Tpng $DOT > layer_${ID}_etl.png
