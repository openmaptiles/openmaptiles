
#!/bin/bash

#  example call from the parent folder :  ./qa/run.sh




# ---- freq ---------------------------------------------------------------
    
mkdir -p ./build/qadoc
rm -f    ./build/qadoc/*.md

./qa/layer_freq.sh aeroway             "class"                    > ./build/qadoc/freq_aeroway__class.md

./qa/layer_freq.sh boundary            "admin_level,disputed"     > ./build/qadoc/freq_boundary__admin_level_disputed.md
./qa/layer_freq.sh boundary            "admin_level"              > ./build/qadoc/freq_boundary__admin_level.md
./qa/layer_freq.sh boundary            "disputed"                 > ./build/qadoc/freq_boundary__disputed.md

./qa/layer_freq.sh building            "render_min_height"        > ./build/qadoc/freq_building__render_min_height.md

#./qa/layer_freq.sh housenumber         "housenumber "        > ./build/qadocfreq_housenumber.md
./qa/layer_freq.sh landcover           "class, subclass"      > ./build/qadoc/freq_landcover__class_subclass.md

./qa/layer_freq.sh landuse             "class "               > ./build/qadoc/freq_landuse__class.md

./qa/layer_freq.sh park                "class "               > ./build/qadoc/freq_park__class.md 

./qa/layer_freq.sh place               "class "               > ./build/qadoc/freq_place__class.md 
./qa/layer_freq.sh place               "class,capital "       > ./build/qadoc/freq_place__class_capital.md
./qa/layer_freq.sh place               "capital "             > ./build/qadoc/freq_place__capital.md   
./qa/layer_freq.sh place               "class,capital,rank "  > ./build/qadoc/freq_place__class_capital_rank.md  
./qa/layer_freq.sh place               "rank "                > ./build/qadoc/freq_place__rank.md 

./qa/layer_freq.sh poi                 "class    "            > ./build/qadoc/freq_poi__class.md  
./qa/layer_freq.sh poi                 "subclass "            > ./build/qadoc/freq_poi__subclass.md
./qa/layer_freq.sh poi                 "rank     "            > ./build/qadoc/freq_poi__rank.md  
./qa/layer_freq.sh poi                 "class,subclass "      > ./build/qadoc/freq_poi__class_subclass.md  
./qa/layer_freq.sh poi                 "class,subclass,rank"  > ./build/qadoc/freq_poi__class_subclass_rank.md  
./qa/layer_freq.sh poi                 "class,rank         "  > ./build/qadoc/freq_poi__class_rank.md

./qa/layer_freq.sh transportation      "class, oneway, ramp, brunnel, service"    > ./build/qadoc/freq_transportation__class_oneway_ramp_brunnel_service.md  
./qa/layer_freq.sh transportation      "oneway, ramp, brunnel, service "          > ./build/qadoc/freq_transportation__oneway_ramp_brunnel_service.md  
./qa/layer_freq.sh transportation      "class "                                   > ./build/qadoc/freq_transportation__class.md  

./qa/layer_freq.sh transportation_name "class "               > ./build/qadoc/freq_transportation_name__class.md  
./qa/layer_freq.sh transportation_name "ref_length"           > ./build/qadoc/freq_transportation_name__ref_length.md

./qa/layer_freq.sh water               "class "               > ./build/qadoc/freq_water__class.md

./qa/layer_freq.sh water_name          "class "               > ./build/qadoc/freq_water_name__class.md

./qa/layer_freq.sh waterway            "class "               > ./build/qadoc/freq_waterway__class.md

# ---- toplength -------------------------------------------

./qa/layer_toplength.sh housenumber         "housenumber"   > ./build/qadoc/toplength_housenumber__housenumber.md 

./qa/layer_toplength.sh place               "name"          > ./build/qadoc/toplength_place__name.md   
./qa/layer_toplength.sh place               "name_en"       > ./build/qadoc/toplength_place__name_en.md   

./qa/layer_toplength.sh poi                 "name"          > ./build/qadoc/toplength_poi__name.md   
./qa/layer_toplength.sh poi                 "name_en"       > ./build/qadoc/toplength_poi__name_en.md   

./qa/layer_toplength.sh transportation_name "name"          > ./build/qadoc/toplength_transportation_name__name.md    
./qa/layer_toplength.sh transportation_name "ref"           > ./build/qadoc/toplength_transportation_name__ref.md 
./qa/layer_toplength.sh transportation_name "network"       > ./build/qadoc/toplength_transportation_name__network.md 

./qa/layer_toplength.sh water_name          "name"          > ./build/qadoc/toplength_water_name__name.md   
./qa/layer_toplength.sh water_name          "name_en"       > ./build/qadoc/toplength_water_name__name_en.md 

./qa/layer_toplength.sh waterway            "name"          > ./build/qadoc/toplength_waterway__name.md   


# ---- numvar analyze -------------------------------------

./qa/layer_numvar_analyze.sh building             "render_min_height"  > ./build/qadoc/numvara_building__render_min_height.md
./qa/layer_numvar_analyze.sh building             "render_max_height"  > ./build/qadoc/numvara_building__render_max_height.md

./qa/layer_numvar_analyze.sh transportation_name  "ref_length"         > ./build/qadoc/numvara_transportation_name__ref_length.md

