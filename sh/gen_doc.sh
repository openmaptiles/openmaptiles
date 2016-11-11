

# Work in progress ...
#
# generate ETL graph from all layers 
# start from the root :
#   ./sh/gen_doc.sh
#
# outut ->  ./doc/ 


mkdir -p ./doc/
rm -f ./doc/*
for f in ./layers/*
do
	echo "Processing : $f"
    layer_id=$(echo "$f" | rev | cut -d"/" -f1 | rev )
    echo "layer_id = $layer_id"
    ./sh/gen_etl_graph.sh $layer_id

done


