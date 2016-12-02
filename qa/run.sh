
#!/bin/bash

#  example call from the parent folder :  ./qa/run.sh

export_path=./build/qadoc

mkdir -p ${export_path}
rm -f    ${export_path}/*.md

# ---- freq 


./qa/layer_freq.sh aeroway             "class"                    > ${export_path}/freq_aeroway.md

./qa/layer_freq.sh boundary            "admin_level,disputed"     > ${export_path}/freq_boundary_admin_level_disputed.md
./qa/layer_freq.sh boundary            "admin_level"              > ${export_path}/freq_boundary_admin_level.md
./qa/layer_freq.sh boundary            "disputed"                 > ${export_path}/freq_boundary_disputed.md

./qa/layer_freq.sh building            "render_min_height"        > ${export_path}/freq_building.md

#./qa/layer_freq.sh housenumber         "housenumber "        > ${export_path}freq_housenumber.md
./qa/layer_freq.sh landcover           "class, subclass"      > ${export_path}/freq_landcover.md

./qa/layer_freq.sh landuse             "class "               > ${export_path}/freq_landuse.md

./qa/layer_freq.sh park                "class "               > ${export_path}/freq_park.md 

./qa/layer_freq.sh place               "class "               > ${export_path}/freq_place_class.md 
./qa/layer_freq.sh place               "class,capital "       > ${export_path}/freq_place_class_capital.md
./qa/layer_freq.sh place               "capital "             > ${export_path}/freq_place_capital.md   
./qa/layer_freq.sh place               "class,capital,rank "  > ${export_path}/freq_place_class_capital_rank.md  
./qa/layer_freq.sh place               "rank "                > ${export_path}/freq_place_rank.md 

./qa/layer_freq.sh poi                 "class    "            > ${export_path}/freq_poi_class.md  
./qa/layer_freq.sh poi                 "subclass "            > ${export_path}/freq_poi_subclass.md
./qa/layer_freq.sh poi                 "rank     "            > ${export_path}/freq_poi_rank.md  
./qa/layer_freq.sh poi                 "class,subclass "      > ${export_path}/freq_poi_class_subclass.md  
./qa/layer_freq.sh poi                 "class,subclass,rank"  > ${export_path}/freq_poi_class_subclass_rank.md  
./qa/layer_freq.sh poi                 "class,rank         "  > ${export_path}/freq_poi_class_rank.md

./qa/layer_freq.sh transportation      "class,subclass "                               > ${export_path}/freq_transportation_class_subclass.md  
./qa/layer_freq.sh transportation      "class,subclass,service,oneway,brunnel,ramp"    > ${export_path}/freq_transportation_class_subclass_service_oneway_brunnel_ramp.md  
./qa/layer_freq.sh transportation      "subclass "                                     > ${export_path}/freq_transportation_subclass.md  
./qa/layer_freq.sh transportation      "class "                                        > ${export_path}/freq_transportation_class.md  

./qa/layer_freq.sh transportation_name "class "               > ${export_path}/freq_transportation_name_class.md  
./qa/layer_freq.sh transportation_name "reflength      "      > ${export_path}/freq_transportation_name_reflength.md

./qa/layer_freq.sh water               "class "               > ${export_path}/freq_water.md

./qa/layer_freq.sh water_name          "class "               > ${export_path}/freq_water_name.md

./qa/layer_freq.sh waterway            "class "               > ${export_path}/freq_waterway.md

# ---- toplength 

./layer_toplength.sh housenumber         "housenumber"   > ${export_path}/toplength_housenumber_housenumber.md 

./layer_toplength.sh place               "name"          > ${export_path}/toplength_place_name.md   
./layer_toplength.sh place               "name_en"       > ${export_path}/toplength_place_name_en.md   

./layer_toplength.sh poi                 "name"          > ${export_path}/toplength_poi_name.md   
./layer_toplength.sh poi                 "name_en"       > ${export_path}/toplength_poi_name_en.md   

./layer_toplength.sh transportation_name "name"          > ${export_path}/toplength_transportation_name.md    
./layer_toplength.sh transportation_name "ref"           > ${export_path}/toplength_transportation_ref.md 
./layer_toplength.sh transportation_name "network"       > ${export_path}/toplength_transportation_network.md 

./layer_toplength.sh water_name          "name"          > ${export_path}/toplength_water_name_name.md   
./layer_toplength.sh water_name          "name_en"       > ${export_path}/toplength_water_name_name_en.md 

./layer_toplength.sh waterway            "name"          > ${export_path}/toplength_waterway_name.md   




# ---- numvar analyze

./qa/layer_numvar_analyze.sh building             "render_min_height"  > ${export_path}/numvara_building_render_min_height.md
./qa/layer_numvar_analyze.sh building             "render_max_height"  > ${export_path}/numvara_building_render_max_height.md

./qa/layer_numvar_analyze.sh transportation_name  "ref_length"         > ${export_path}/numvara_transportation_name_ref_length.md

