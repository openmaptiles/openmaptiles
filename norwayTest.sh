echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Run norwayTest.sh "

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Run download area "

#make download-geofabrik area=planet

echo "... complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Run Cleanup and initiation"

#make clean

#make 

echo "... complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import natural earth data  "

#make import-data 

echo "...complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import osm  "

#make import-osm area=planet

echo "... Complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import wikidata  "

#make import-wikidata 

echo "... Complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : import sql  "

make import-sql

echo "... Complete!"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : generate tiles  "

make generate-tiles-pg 

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : script complete  "
