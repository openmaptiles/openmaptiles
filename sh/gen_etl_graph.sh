


# Work in progress ...
#
# generate ETL graph from a single layer 
# start from the root 
# parameter1: "layer name"  
#   ./sh/gen_etl_graph.sh  waterway
#
# outut ->  ./doc/ 

ID=$1 
## ID=waterway

mkdir -p ./doc
layer_dir=./layers/${ID}/
DOT=./doc/dot_${ID}.dot


echo "digraph G
{    
rankdir=LR;
" > $DOT

if [  -f ${layer_dir}/mapping.yaml ]; then
    echo "processing imposm3 mapping file ${layer_dir}/mapping.yaml "
    cat ${layer_dir}/mapping.yaml    | grep    "# etldoc:" |  sed 's/# etldoc://g'  >>$DOT
fi


for f in ${layer_dir}*.sql
do
	echo "Processing : $f"
    cat $f  | grep "\-\- etldoc:" |  sed 's/-- etldoc://g' >>$DOT
done

echo "
}
" >> $DOT

##cat $DOT

dot -Tpng $DOT > ./doc/etl_layer_${ID}.png
dot -Tsvg $DOT > ./doc/etl_layer_${ID}.svg
