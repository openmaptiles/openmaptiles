#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

#  example call from the parent folder :  ./qa/run.sh
#                                    or    make generate-qareports

# ---- freq ---------------------------------------------------------------

mkdir -p ./build/qareports
rm -f    ./build/qareports/*.md

# -----

./qa/layer_freq.sh aeroway             "class"                    > ./build/qareports/freq_aeroway__class.md

###Todo:./qa/layer_freq.sh boundary            "admin_level,disputed"     > ./build/qareports/freq_boundary__admin_level_disputed.md
./qa/layer_freq.sh boundary            "admin_level"              > ./build/qareports/freq_boundary__admin_level.md
###Todo: ./qa/layer_freq.sh boundary            "disputed"                 > ./build/qareports/freq_boundary__disputed.md

./qa/layer_freq.sh building            "render_min_height"        > ./build/qareports/freq_building__render_min_height.md

#./qa/layer_freq.sh housenumber         "housenumber "        > ./build/qadocfreq_housenumber.md
./qa/layer_freq.sh landcover           "class, subclass"      > ./build/qareports/freq_landcover__class_subclass.md

./qa/layer_freq.sh landuse             "class "               > ./build/qareports/freq_landuse__class.md

./qa/layer_freq.sh park                "class "               > ./build/qareports/freq_park__class.md

./qa/layer_freq.sh place               "class "               > ./build/qareports/freq_place__class.md
./qa/layer_freq.sh place               "class,capital "       > ./build/qareports/freq_place__class_capital.md
./qa/layer_freq.sh place               "capital "             > ./build/qareports/freq_place__capital.md
./qa/layer_freq.sh place               "class,capital,rank "  > ./build/qareports/freq_place__class_capital_rank.md
./qa/layer_freq.sh place               "rank "                > ./build/qareports/freq_place__rank.md

./qa/layer_freq.sh poi                 "class    "            > ./build/qareports/freq_poi__class.md
./qa/layer_freq.sh poi                 "subclass "            > ./build/qareports/freq_poi__subclass.md
./qa/layer_freq.sh poi                 "rank     "            > ./build/qareports/freq_poi__rank.md
./qa/layer_freq.sh poi                 "class,subclass "      > ./build/qareports/freq_poi__class_subclass.md
./qa/layer_freq.sh poi                 "class,subclass,rank"  > ./build/qareports/freq_poi__class_subclass_rank.md
./qa/layer_freq.sh poi                 "class,rank         "  > ./build/qareports/freq_poi__class_rank.md

./qa/layer_freq.sh transportation      "class, oneway, ramp, brunnel, service"    > ./build/qareports/freq_transportation__class_oneway_ramp_brunnel_service.md
./qa/layer_freq.sh transportation      "oneway, ramp, brunnel, service "          > ./build/qareports/freq_transportation__oneway_ramp_brunnel_service.md
./qa/layer_freq.sh transportation      "class "                                   > ./build/qareports/freq_transportation__class.md

./qa/layer_freq.sh transportation_name "class "               > ./build/qareports/freq_transportation_name__class.md
./qa/layer_freq.sh transportation_name "ref_length"           > ./build/qareports/freq_transportation_name__ref_length.md

./qa/layer_freq.sh water               "class "               > ./build/qareports/freq_water__class.md

./qa/layer_freq.sh water_name          "class "               > ./build/qareports/freq_water_name__class.md

./qa/layer_freq.sh waterway            "class "               > ./build/qareports/freq_waterway__class.md

# ---- toplength -------------------------------------------

./qa/layer_toplength.sh housenumber         "housenumber"   > ./build/qareports/toplength_housenumber__housenumber.md

./qa/layer_toplength.sh place               "name"          > ./build/qareports/toplength_place__name.md
./qa/layer_toplength.sh place               "name_en"       > ./build/qareports/toplength_place__name_en.md

./qa/layer_toplength.sh poi                 "name"          > ./build/qareports/toplength_poi__name.md
./qa/layer_toplength.sh poi                 "name_en"       > ./build/qareports/toplength_poi__name_en.md

./qa/layer_toplength.sh transportation_name "name"          > ./build/qareports/toplength_transportation_name__name.md
./qa/layer_toplength.sh transportation_name "ref"           > ./build/qareports/toplength_transportation_name__ref.md
###Todo: ./qa/layer_toplength.sh transportation_name "network"       > ./build/qareports/toplength_transportation_name__network.md

./qa/layer_toplength.sh water_name          "name"          > ./build/qareports/toplength_water_name__name.md
./qa/layer_toplength.sh water_name          "name_en"       > ./build/qareports/toplength_water_name__name_en.md

./qa/layer_toplength.sh waterway            "name"          > ./build/qareports/toplength_waterway__name.md


# ---- numvar analyze -------------------------------------

./qa/layer_numvar_analyze.sh building             "render_min_height"  > ./build/qareports/numvara_building__render_min_height.md
./qa/layer_numvar_analyze.sh building             "render_height"      > ./build/qareports/numvara_building__render_height.md

./qa/layer_numvar_analyze.sh transportation_name  "ref_length"         > ./build/qareports/numvara_transportation_name__ref_length.md

