echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Run planetTest.sh "

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Run download area "

#make download-geofabrik area=planet
#make destroy-db
#make stop-db
#make clean-unnecessary-docker
#make remove-docker-images
#make refresh-docker-images

echo "... complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Run Cleanup and initiation"

make clean

make 

echo "... complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import natural earth data  "

make import-data 

echo "...complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import osm  "

make import-osm area=planet

echo "... Complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import wikidata  "

make import-wikidata 

echo "... Complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import sql  "

make import-sql

echo "... Complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : generate tiles  "

make generate-bbox-file area=planet

make generate-tiles-pg 

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : script complete  "
