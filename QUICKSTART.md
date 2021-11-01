## Quickstart - for small extracts

### Req:
* CPU: AMD64 ( = Intel 64 bit)
    *  The base docker debian images are x86_64 based, so the ARM,MIPS currently not supported!
* Operating system
    * Linux is suggested
        * The development and the testing platform is Linux.
    * If you are using FreeBSD, Solaris, Windows, ...
        * Please give a feedback, share your experience, write a tutorial
* bash
* git
* make
* bc
* md5sum
* docker         >=1.12.3
    * https://www.docker.com/products/overview
* docker-compose >=1.7.1
    * https://docs.docker.com/compose/install/
* disk space ( >= ~15Gb  )
    * for small extracts  >= ~15Gb
    * for big extracts ( continents, planet) 250 Gb
    * And depends on
        * OpenStreetMap data size
        * Zoom level
    * Best on SSD for postserve but completely usable on HDD
    * Takes 24hrs to import on a reasonable machine, and is immediately available with postserve
* memory ( >= 3Gb )
    * for small extracts 3Gb-8Gb RAM
    * for big extracts ( Europe, Planet) > 8-32 Gb
* internet connections
    * for downloading docker images
    * for downloading OpenStreetMap data from Geofabrik

Important:  The ./quickstart.sh is for small extracts - not optimal for a Planet rendering !!

### First experiment - with `albania` ( small extracts! )

```bash
git clone https://github.com/openmaptiles/openmaptiles.git
cd openmaptiles
./quickstart.sh
```

If you have problems with the quickstart
* check the ./quickstart.log!
* doublecheck the system requirements!
* check the current issues: https://github.com/openmaptiles/openmaptiles/issues
* create new issues:
    * create a new gist: https://gist.github.com/ from your ./quickstart.log
    * doublecheck: don't reveal any sensitive information about your system
    * create a new issue: https://github.com/openmaptiles/openmaptiles/issues
        * describe the problems
        * add any pertinent information about your environment
        * link your (quickstart.log) gist!

### Check other extracts

IF the previous step is working,
THEN you can test other available quickstart extracts ( based on [Geofabrik extracts](http://download.geofabrik.de/index.html) ) !
 * We are using https://github.com/julien-noblet/download-geofabrik tool
 * The current extract list, and more information  ->  `make list`

This is generating `.mbtiles` for your area :  [ MIN_ZOOM: "0"  - MAX_ZOOM: "7" ]

```bash
./quickstart.sh africa                       # Africa
./quickstart.sh alabama                      # Alabama, US
./quickstart.sh alaska                       # Alaska, US
./quickstart.sh albania                      # Albania, Europe
./quickstart.sh alberta                      # Alberta, Canada
./quickstart.sh alps                         # Alps, Europe
./quickstart.sh alsace                       # Alsace, France
./quickstart.sh andorra                      # Andorra, Europe
./quickstart.sh antarctica                   # Antarctica
./quickstart.sh aquitaine                    # Aquitaine, France
./quickstart.sh argentina                    # Argentina, South-America
./quickstart.sh arizona                      # Arizona, US
./quickstart.sh arkansas                     # Arkansas, US
./quickstart.sh arnsberg-regbez              # Regierungsbezirk Arnsberg, Nordrhein-Westfalen
./quickstart.sh asia                         # Asia
./quickstart.sh australia                    # Australia, Australia-Oceania
./quickstart.sh australia-oceania            # Australia and Oceania
./quickstart.sh austria                      # Austria, Europe
./quickstart.sh auvergne                     # Auvergne, France
./quickstart.sh azerbaijan                   # Azerbaijan, Asia
./quickstart.sh azores                       # Azores, Europe
./quickstart.sh baden-wuerttemberg           # Baden-Württemberg, Germany
./quickstart.sh bangladesh                   # Bangladesh, Asia
./quickstart.sh basse-normandie              # Basse-Normandie, France
./quickstart.sh bayern                       # Bayern, Germany
./quickstart.sh belarus                      # Belarus, Europe
./quickstart.sh belgium                      # Belgium, Europe
./quickstart.sh belize                       # Belize, Central-America
./quickstart.sh berlin                       # Berlin, Germany
./quickstart.sh bolivia                      # Bolivia, South-America
./quickstart.sh bosnia-herzegovina           # Bosnia-Herzegovina, Europe
./quickstart.sh botswana                     # Botswana, Africa
./quickstart.sh bourgogne                    # Bourgogne, France
./quickstart.sh brandenburg                  # Brandenburg, Germany
./quickstart.sh brazil                       # Brazil, South-America
./quickstart.sh bremen                       # Bremen, Germany
./quickstart.sh bretagne                     # Bretagne, France
./quickstart.sh british-columbia             # British Columbia, Canada
./quickstart.sh british-isles                # British Isles, Europe
./quickstart.sh buckinghamshire              # Buckinghamshire, England
./quickstart.sh bulgaria                     # Bulgaria, Europe
./quickstart.sh burkina-faso                 # Burkina Faso, Africa
./quickstart.sh california                   # California, US
./quickstart.sh cambridgeshire               # Cambridgeshire, England
./quickstart.sh cameroon                     # Cameroon
./quickstart.sh canada                       # Canada, North-America
./quickstart.sh canary-islands               # Canary Islands, Africa
./quickstart.sh central-america              # Central America
./quickstart.sh centre                       # Centre, France
./quickstart.sh champagne-ardenne            # Champagne Ardenne, France
./quickstart.sh cheshire                     # Cheshire, England
./quickstart.sh chile                        # Chile, South-America
./quickstart.sh china                        # China, Asia
./quickstart.sh colombia                     # Colombia, South-America
./quickstart.sh colorado                     # Colorado, US
./quickstart.sh congo-democratic-republic    # Congo (Democratic Republic), Africa
./quickstart.sh connecticut                  # Connecticut, US
./quickstart.sh cornwall                     # Cornwall, England
./quickstart.sh corse                        # Corse, France
./quickstart.sh croatia                      # Croatia, Europe
./quickstart.sh cuba                         # Cuba, Central-America
./quickstart.sh cumbria                      # Cumbria, England
./quickstart.sh cyprus                       # Cyprus, Europe
./quickstart.sh czech-republic               # Czech Republic, Europe
./quickstart.sh dach                         # Germany, Austria, Switzerland, Europe
./quickstart.sh delaware                     # Delaware, US
./quickstart.sh denmark                      # Denmark, Europe
./quickstart.sh derbyshire                   # Derbyshire, England
./quickstart.sh detmold-regbez               # Regierungsbezirk Detmold, Nordrhein-Westfalen
./quickstart.sh devon                        # Devon, England
./quickstart.sh district-of-columbia         # District of Columbia, US
./quickstart.sh dorset                       # Dorset, England
./quickstart.sh duesseldorf-regbez           # Regierungsbezirk Düsseldorf, Nordrhein-Westfalen
./quickstart.sh east-sussex                  # East Sussex, England
./quickstart.sh east-yorkshire-with-hull     # East Yorkshire with Hull, England
./quickstart.sh ecuador                      # Ecuador, South-America
./quickstart.sh egypt                        # Egypt, Africa
./quickstart.sh england                      # England, Great-Britain
./quickstart.sh essex                        # Essex, England
./quickstart.sh estonia                      # Estonia, Europe
./quickstart.sh ethiopia                     # Ethiopia, Africa
./quickstart.sh europe                       # Europe
./quickstart.sh faroe-islands                # Faroe Islands, Europe
./quickstart.sh fiji                         # Fiji, Australia-Oceania
./quickstart.sh finland                      # Finland, Europe
./quickstart.sh florida                      # Florida, US
./quickstart.sh france                       # France, Europe
./quickstart.sh franche-comte                # Franche Comte, France
./quickstart.sh freiburg-regbez              # Regierungsbezirk Freiburg, Baden-Wuerttemberg
./quickstart.sh gcc-states                   # GCC States, Asia
./quickstart.sh georgia-eu                   # Georgia (Eastern Europe), Europe
./quickstart.sh georgia-us                   # Georgia (US State), US
./quickstart.sh germany                      # Germany, Europe
./quickstart.sh gloucestershire              # Gloucestershire, England
./quickstart.sh great-britain                # Great Britain, Europe
./quickstart.sh greater-london               # Greater London, England
./quickstart.sh greater-manchester           # Greater Manchester, England
./quickstart.sh greece                       # Greece, Europe
./quickstart.sh greenland                    # Greenland, North-America
./quickstart.sh guadeloupe                   # Guadeloupe, France
./quickstart.sh guatemala                    # Guatemala, Central-America
./quickstart.sh guinea                       # Guinea, Africa
./quickstart.sh guinea-bissau                # Guinea-Bissau, Africa
./quickstart.sh guyane                       # Guyane, France
./quickstart.sh haiti-and-domrep             # Haiti and Dominican Republic, Central-America
./quickstart.sh hamburg                      # Hamburg, Germany
./quickstart.sh hampshire                    # Hampshire, England
./quickstart.sh haute-normandie              # Haute-Normandie, France
./quickstart.sh hawaii                       # Hawaii, US
./quickstart.sh herefordshire                # Herefordshire, England
./quickstart.sh hertfordshire                # Hertfordshire, England
./quickstart.sh hessen                       # Hessen, Germany
./quickstart.sh hungary                      # Hungary, Europe
./quickstart.sh iceland                      # Iceland, Europe
./quickstart.sh idaho                        # Idaho, US
./quickstart.sh ile-de-france                # Ile-de-France, France
./quickstart.sh illinois                     # Illinois, US
./quickstart.sh india                        # India, Asia
./quickstart.sh indiana                      # Indiana, US
./quickstart.sh indonesia                    # Indonesia, Asia
./quickstart.sh iowa                         # Iowa, US
./quickstart.sh irak                         # Irak, Asia
./quickstart.sh iran                         # Iran, Asia
./quickstart.sh ireland-and-northern-ireland # Ireland and Northern Ireland, Europe
./quickstart.sh isle-of-man                  # Isle of Man, Europe
./quickstart.sh isle-of-wight                # Isle of Wight, England
./quickstart.sh israel-and-palestine         # Israel and Palestine, Asia
./quickstart.sh italy                        # Italy, Europe
./quickstart.sh ivory-coast                  # Ivory Coast, Africa
./quickstart.sh japan                        # Japan, Asia
./quickstart.sh jordan                       # Jordan, Asia
./quickstart.sh kansas                       # Kansas, US
./quickstart.sh karlsruhe-regbez             # Regierungsbezirk Karlsruhe, Baden-Wuerttemberg
./quickstart.sh kazakhstan                   # Kazakhstan, Asia
./quickstart.sh kent                         # Kent, England
./quickstart.sh kentucky                     # Kentucky, US
./quickstart.sh kenya                        # Kenya, Africa
./quickstart.sh koeln-regbez                 # Regierungsbezirk Köln, Nordrhein-Westfalen
./quickstart.sh kosovo                       # Kosovo, Europe
./quickstart.sh kyrgyzstan                   # Kyrgyzstan, Asia
./quickstart.sh lancashire                   # Lancashire, England
./quickstart.sh languedoc-roussillon         # Languedoc-Roussillon, France
./quickstart.sh latvia                       # Latvia, Europe
./quickstart.sh lebanon                      # Lebanon, Asia
./quickstart.sh leicestershire               # Leicestershire, England
./quickstart.sh lesotho                      # Lesotho, Africa
./quickstart.sh liberia                      # Liberia, Africa
./quickstart.sh libya                        # Libya, Africa
./quickstart.sh liechtenstein                # Liechtenstein, Europe
./quickstart.sh limousin                     # Limousin, France
./quickstart.sh lithuania                    # Lithuania, Europe
./quickstart.sh lorraine                     # Lorraine, France
./quickstart.sh louisiana                    # Louisiana, US
./quickstart.sh luxembourg                   # Luxembourg, Europe
./quickstart.sh macedonia                    # Macedonia, Europe
./quickstart.sh madagascar                   # Madagascar, Africa
./quickstart.sh maine                        # Maine, US
./quickstart.sh malaysia-singapore-brunei    # Malaysia, Singapore, and Brunei, Asia
./quickstart.sh malta                        # Malta, Europe
./quickstart.sh manitoba                     # Manitoba, Canada
./quickstart.sh martinique                   # Martinique, France
./quickstart.sh maryland                     # Maryland, US
./quickstart.sh massachusetts                # Massachusetts, US
./quickstart.sh mayotte                      # Mayotte, France
./quickstart.sh mecklenburg-vorpommern       # Mecklenburg-Vorpommern, Germany
./quickstart.sh mexico                       # Mexico, North-America
./quickstart.sh michigan                     # Michigan, US
./quickstart.sh midi-pyrenees                # Midi-Pyrenees, France
./quickstart.sh minnesota                    # Minnesota, US
./quickstart.sh mississippi                  # Mississippi, US
./quickstart.sh missouri                     # Missouri, US
./quickstart.sh mittelfranken                # Mittelfranken, Bayern
./quickstart.sh moldova                      # Moldova, Europe
./quickstart.sh monaco                       # Monaco, Europe
./quickstart.sh mongolia                     # Mongolia, Asia
./quickstart.sh montana                      # Montana, US
./quickstart.sh montenegro                   # Montenegro, Europe
./quickstart.sh morocco                      # Morocco, Africa
./quickstart.sh muenster-regbez              # Regierungsbezirk Münster, Nordrhein-Westfalen
./quickstart.sh nebraska                     # Nebraska, US
./quickstart.sh nepal                        # Nepal, Asia
./quickstart.sh netherlands                  # Netherlands, Europe
./quickstart.sh nevada                       # Nevada, US
./quickstart.sh new-brunswick                # New Brunswick, Canada
./quickstart.sh new-caledonia                # New Caledonia, Australia-Oceania
./quickstart.sh new-hampshire                # New Hampshire, US
./quickstart.sh new-jersey                   # New Jersey, US
./quickstart.sh new-mexico                   # New Mexico, US
./quickstart.sh new-york                     # New York, US
./quickstart.sh new-zealand                  # New Zealand, Australia-Oceania
./quickstart.sh newfoundland-and-labrador    # Newfoundland and Labrador, Canada
./quickstart.sh niederbayern                 # Niederbayern, Bayern
./quickstart.sh niedersachsen                # Niedersachsen, Germany
./quickstart.sh nigeria                      # Nigeria, Africa
./quickstart.sh nord-pas-de-calais           # Nord-Pas-de-Calais, France
./quickstart.sh nordrhein-westfalen          # Nordrhein-Westfalen, Germany
./quickstart.sh norfolk                      # Norfolk, England
./quickstart.sh north-america                # North America
./quickstart.sh north-carolina               # North Carolina, US
./quickstart.sh north-dakota                 # North Dakota, US
./quickstart.sh north-korea                  # North Korea, Asia
./quickstart.sh north-yorkshire              # North Yorkshire, England
./quickstart.sh northwest-territories        # Northwest Territories, Canada
./quickstart.sh norway                       # Norway, Europe
./quickstart.sh nottinghamshire              # Nottinghamshire, England
./quickstart.sh nova-scotia                  # Nova Scotia, Canada
./quickstart.sh nunavut                      # Nunavut, Canada
./quickstart.sh oberbayern                   # Oberbayern, Bayern
./quickstart.sh oberfranken                  # Oberfranken, Bayern
./quickstart.sh oberpfalz                    # Oberpfalz, Bayern
./quickstart.sh ohio                         # Ohio, US
./quickstart.sh oklahoma                     # Oklahoma, US
./quickstart.sh ontario                      # Ontario, Canada
./quickstart.sh oregon                       # Oregon, US
./quickstart.sh oxfordshire                  # Oxfordshire, England
./quickstart.sh pakistan                     # Pakistan, Asia
./quickstart.sh paraguay                     # Paraguay, South-America
./quickstart.sh pays-de-la-loire             # Pays de la Loire, France
./quickstart.sh pennsylvania                 # Pennsylvania, US
./quickstart.sh peru                         # Peru, South-America
./quickstart.sh philippines                  # Philippines, Asia
./quickstart.sh picardie                     # Picardie, France
./quickstart.sh poitou-charentes             # Poitou-Charentes, France
./quickstart.sh poland                       # Poland, Europe
./quickstart.sh portugal                     # Portugal, Europe
./quickstart.sh prince-edward-island         # Prince Edward Island, Canada
./quickstart.sh provence-alpes-cote-d-azur   # Provence Alpes-Cote-d'Azur, France
./quickstart.sh quebec                       # Quebec, Canada
./quickstart.sh reunion                      # Reunion, France
./quickstart.sh rheinland-pfalz              # Rheinland-Pfalz, Germany
./quickstart.sh rhode-island                 # Rhode Island, US
./quickstart.sh rhone-alpes                  # Rhone-Alpes, France
./quickstart.sh romania                      # Romania, Europe
./quickstart.sh russia-asian-part            # Russia (Asian part), Asia
./quickstart.sh russia-european-part         # Russia (European part), Europe
./quickstart.sh saarland                     # Saarland, Germany
./quickstart.sh sachsen                      # Sachsen, Germany
./quickstart.sh sachsen-anhalt               # Sachsen-Anhalt, Germany
./quickstart.sh saskatchewan                 # Saskatchewan, Canada
./quickstart.sh schleswig-holstein           # Schleswig-Holstein, Germany
./quickstart.sh schwaben                     # Schwaben, Bayern
./quickstart.sh scotland                     # Scotland, Great-Britain
./quickstart.sh serbia                       # Serbia, Europe
./quickstart.sh shropshire                   # Shropshire, England
./quickstart.sh sierra-leone                 # Sierra Leone, Africa
./quickstart.sh slovakia                     # Slovakia, Europe
./quickstart.sh slovenia                     # Slovenia, Europe
./quickstart.sh somalia                      # Somalia, Africa
./quickstart.sh somerset                     # Somerset, England
./quickstart.sh south-africa-and-lesotho     # South Africa (includes Lesotho), Africa
./quickstart.sh south-america                # South America
./quickstart.sh south-carolina               # South Carolina, US
./quickstart.sh south-dakota                 # South Dakota, US
./quickstart.sh south-korea                  # South Korea, Asia
./quickstart.sh south-yorkshire              # South Yorkshire, England
./quickstart.sh spain                        # Spain, Europe
./quickstart.sh sri-lanka                    # Sri Lanka, Asia
./quickstart.sh staffordshire                # Staffordshire, England
./quickstart.sh stuttgart-regbez             # Regierungsbezirk Stuttgart, Baden-Wuerttemberg
./quickstart.sh suffolk                      # Suffolk, England
./quickstart.sh surrey                       # Surrey, England
./quickstart.sh sweden                       # Sweden, Europe
./quickstart.sh switzerland                  # Switzerland, Europe
./quickstart.sh syria                        # Syria, Asia
./quickstart.sh taiwan                       # Taiwan, Asia
./quickstart.sh tajikistan                   # Tajikistan, Asia
./quickstart.sh tanzania                     # Tanzania, Africa
./quickstart.sh tennessee                    # Tennessee, US
./quickstart.sh texas                        # Texas, US
./quickstart.sh thailand                     # Thailand, Asia
./quickstart.sh thueringen                   # Thüringen, Germany
./quickstart.sh tuebingen-regbez             # Regierungsbezirk Tübingen, Baden-Wuerttemberg
./quickstart.sh turkey                       # Turkey, Europe
./quickstart.sh turkmenistan                 # Turkmenistan, Asia
./quickstart.sh ukraine                      # Ukraine, Europe
./quickstart.sh unterfranken                 # Unterfranken, Bayern
./quickstart.sh uruguay                      # Uruguay, South-America
./quickstart.sh us-midwest                   # US Midwest, North-America
./quickstart.sh us-northeast                 # US Northeast, North-America
./quickstart.sh us-pacific                   # US Pacific, North-America
./quickstart.sh us-south                     # US South, North-America
./quickstart.sh us-west                      # US West, North-America
./quickstart.sh utah                         # Utah, US
./quickstart.sh uzbekistan                   # Uzbekistan, Asia
./quickstart.sh vermont                      # Vermont, US
./quickstart.sh vietnam                      # Vietnam, Asia
./quickstart.sh virginia                     # Virginia, US
./quickstart.sh wales                        # Wales, Great-Britain
./quickstart.sh washington                   # Washington, US
./quickstart.sh west-midlands                # West Midlands, England
./quickstart.sh west-sussex                  # West Sussex, England
./quickstart.sh west-virginia                # West Virginia, US
./quickstart.sh west-yorkshire               # West Yorkshire, England
./quickstart.sh wiltshire                    # Wiltshire, England
./quickstart.sh wisconsin                    # Wisconsin, US
./quickstart.sh wyoming                      # Wyoming, US
./quickstart.sh yukon                        # Yukon, Canada
```
### Using your own OSM data
Mbtiles can be generated from an arbitrary osm.pbf (e.g. for a region that is not covered by an existing extract) by making the `data/` directory and placing an *.osm.pbf (e.g. `mydata.osm.pbf`) inside.

```
mkdir -p data
mv mydata.osm.pbf data/
make generate-bbox-file area=mydata
./quickstart.sh mydata
```

### Check postserve
*  ` docker-compose up -d postserve`
and the generated maps are going to be available in browser on [localhost:8090/tiles/0/0/0.pbf](http://localhost:8090/tiles/0/0/0.pbf).

### Check tileserver

start:
*  ` make start-tileserver`
and the generated maps are going to be available in webbrowser on [localhost:8080](http://localhost:8080/).

This is only a quick preview, because your mbtiles only generated to zoom level 7 !


### Set which zooms to generate

modify the settings in the `.env` file, the defaults:
* `MIN_ZOOM=0`
* `MAX_ZOOM=7`

Hints:
* Small increments! Never starts with the `MAX_ZOOM = 14`
* The suggested  `MAX_ZOOM = 14`  - use only with small extracts

### Set the bounding box to generate

By default, tile generation is done for the full extent of the area.
If you want to generate a tiles for a smaller extent, modify the settings in the `.env` file, the default:
* `BBOX=-180.0,-85.0511,180.0,85.0511`

Delete the `./data/<area>.bbox` file, and re-start `./quickstart.sh <area>`

Hint:
* The [boundingbox.klokantech.com](https://boundingbox.klokantech.com/) site can be used to find a bounding box (CSV format) using a map.

### Check other commands

`make help`


the current output:

```
==============================================================================
OpenMapTiles  https://github.com/openmaptiles/openmaptiles

Hints for testing areas
  make list-geofabrik                  # list actual geofabrik OSM extracts for download -> <<your-area>>
  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar

Hints for designers:
  make start-maputnik                  # start Maputnik Editor + dynamic tile server [ see http://localhost:8088 ]
  make start-postserve                 # start dynamic tile server                   [ see http://localhost:8090 ]
  make stop-postserve                  # stop dynamic tile server
  make start-tileserver                # start maptiler/tileserver-gl                [ see http://localhost:8080 ]

Hints for developers:
  make                                 # build source code
  make bash                            # start openmaptiles-tools /bin/bash terminal
  make generate-bbox-file              # compute bounding box of a data file and store it in a file
  make generate-devdoc                 # generate devdoc including graphs for all layers [./layers/...]
  make generate-qa                     # statistics for a given layer's field
  make generate-tiles-pg               # generate vector tiles based on .env settings using PostGIS ST_MVT()
  make generate-tiles                  # generate vector tiles based on .env settings using Mapnik (obsolete)
  make test-sql                        # run unit tests on the OpenMapTiles SQL schema
  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information
  cat  quickstart.log                  # transcript of the last ./quickstart.sh run
  make help                            # help about available commands

Hints for downloading & importing data:
  make list-geofabrik                  # list actual geofabrik OSM extracts for download
  make list-bbbike                     # list actual BBBike OSM extracts for download
  make download area=albania           # download OSM data from any source       and create config file
  make download-geofabrik area=albania # download OSM data from geofabrik.de     and create config file
  make download-osmfr area=asia/qatar  # download OSM data from openstreetmap.fr and create config file
  make download-bbbike area=Amsterdam  # download OSM data from bbbike.org       and create config file
  make import-data                     # Import data from OpenStreetMapData, Natural Earth and OSM Lake Labels.
  make import-osm                      # Import OSM data with the mapping rules from build/mapping.yaml
  make import-wikidata                 # Import labels from Wikidata
  make import-sql                      # Import layers (run this after modifying layer SQL)

Hints for database management:
  make psql                            # start PostgreSQL console
  make psql-list-tables                # list all PostgreSQL tables
  make list-views                      # list PostgreSQL public schema views
  make list-tables                     # list PostgreSQL public schema tables
  make vacuum-db                       # PostgreSQL: VACUUM ANALYZE
  make analyze-db                      # PostgreSQL: ANALYZE
  make destroy-db                      # remove docker containers and PostgreSQL data volume
  make start-db                        # start PostgreSQL, creating it if it doesn't exist
  make start-db-preloaded              # start PostgreSQL, creating data-prepopulated one if it doesn't exist
  make stop-db                         # stop PostgreSQL database without destroying the data

Hints for Docker management:
  make clean-unnecessary-docker        # clean unnecessary docker image(s) and container(s)
  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB
  make remove-docker-images            # remove openmaptiles docker images
  make list-docker-images              # show a list of available docker images
==============================================================================
```
