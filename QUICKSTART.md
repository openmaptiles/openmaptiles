

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
* check again the system requirements!
* check the current issues : https://github.com/openmaptiles/openmaptiles/issues 
* create new issues: 
    * create a new gist https://gist.github.com/ from your ./quickstart.log
    * double check: if this is not contain any sensitive informations about your system   
    * create a new issues: https://github.com/openmaptiles/openmaptiles/issues
        * describe the problems  
        * add any important informations your environment 
        * and link your (quickstart.log) gist !
    
### Check other extracts

IF the previous step is working,
THAN you can test other available quickstart extracts ( based on [Geofabrik extracts](http://download.geofabrik.de/index.html) ) !
 * We are using https://github.com/julien-noblet/download-geofabrik tool
 * The current extract list, and more informations  ->  `make list`

This is generating `.mbtiles` for your area :  [ MIN_ZOOM: "0"  - MAX_ZOOM: "7" ]

```bash
./quickstart.sh africa          # Africa,
./quickstart.sh alabama          # Alabama,us
./quickstart.sh alaska          # Alaska,us
./quickstart.sh albania          # Albania,europe
./quickstart.sh alberta          # Alberta,canada
./quickstart.sh alps          # Alps,europe
./quickstart.sh alsace          # Alsace,france
./quickstart.sh andorra          # Andorra,europe
./quickstart.sh antarctica          # Antarctica,
./quickstart.sh aquitaine          # Aquitaine,france
./quickstart.sh argentina          # Argentina,south-america
./quickstart.sh arizona          # Arizona,us
./quickstart.sh arkansas          # Arkansas,us
./quickstart.sh arnsberg-regbez          # Regierungsbezirk Arnsberg,nordrhein-westfalen
./quickstart.sh asia          # Asia,
./quickstart.sh australia          # Australia,australia-oceania
./quickstart.sh australia-oceania          # Australia and Oceania,
./quickstart.sh austria          # Austria,europe
./quickstart.sh auvergne          # Auvergne,france
./quickstart.sh azerbaijan          # Azerbaijan,asia
./quickstart.sh azores          # Azores,europe
./quickstart.sh baden-wuerttemberg          # Baden-Württemberg,germany
./quickstart.sh bangladesh          # Bangladesh,asia
./quickstart.sh basse-normandie          # Basse-Normandie,france
./quickstart.sh bayern          # Bayern,germany
./quickstart.sh belarus          # Belarus,europe
./quickstart.sh belgium          # Belgium,europe
./quickstart.sh belize          # Belize,central-america
./quickstart.sh berlin          # Berlin,germany
./quickstart.sh bolivia          # Bolivia,south-america
./quickstart.sh bosnia-herzegovina          # Bosnia-Herzegovina,europe
./quickstart.sh botswana          # Botswana,africa
./quickstart.sh bourgogne          # Bourgogne,france
./quickstart.sh brandenburg          # Brandenburg,germany
./quickstart.sh brazil          # Brazil,south-america
./quickstart.sh bremen          # Bremen,germany
./quickstart.sh bretagne          # Bretagne,france
./quickstart.sh british-columbia          # British Columbia,canada
./quickstart.sh british-isles          # British Isles,europe
./quickstart.sh buckinghamshire          # Buckinghamshire,england
./quickstart.sh bulgaria          # Bulgaria,europe
./quickstart.sh burkina-faso          # Burkina Faso,africa
./quickstart.sh california          # California,us
./quickstart.sh cambridgeshire          # Cambridgeshire,england
./quickstart.sh cameroon          # Cameroon,
./quickstart.sh canada          # Canada,north-america
./quickstart.sh canary-islands          # Canary Islands,africa
./quickstart.sh central-america          # Central America,
./quickstart.sh centre          # Centre,france
./quickstart.sh champagne-ardenne          # Champagne Ardenne,france
./quickstart.sh cheshire          # Cheshire,england
./quickstart.sh chile          # Chile,south-america
./quickstart.sh china          # China,asia
./quickstart.sh colombia          # Colombia,south-america
./quickstart.sh colorado          # Colorado,us
./quickstart.sh congo-democratic-republic          # Congo (Democratic Republic),africa
./quickstart.sh connecticut          # Connecticut,us
./quickstart.sh cornwall          # Cornwall,england
./quickstart.sh corse          # Corse,france
./quickstart.sh croatia          # Croatia,europe
./quickstart.sh cuba          # Cuba,central-america
./quickstart.sh cumbria          # Cumbria,england
./quickstart.sh cyprus          # Cyprus,europe
./quickstart.sh czech-republic          # Czech Republic,europe
./quickstart.sh dach          # Germany, Austria, Switzerland,europe
./quickstart.sh delaware          # Delaware,us
./quickstart.sh denmark          # Denmark,europe
./quickstart.sh derbyshire          # Derbyshire,england
./quickstart.sh detmold-regbez          # Regierungsbezirk Detmold,nordrhein-westfalen
./quickstart.sh devon          # Devon,england
./quickstart.sh district-of-columbia          # District of Columbia,us
./quickstart.sh dorset          # Dorset,england
./quickstart.sh duesseldorf-regbez          # Regierungsbezirk Düsseldorf,nordrhein-westfalen
./quickstart.sh east-sussex          # East Sussex,england
./quickstart.sh east-yorkshire-with-hull          # East Yorkshire with Hull,england
./quickstart.sh ecuador          # Ecuador,south-america
./quickstart.sh egypt          # Egypt,africa
./quickstart.sh england          # England,great-britain
./quickstart.sh essex          # Essex,england
./quickstart.sh estonia          # Estonia,europe
./quickstart.sh ethiopia          # Ethiopia,africa
./quickstart.sh europe          # Europe,
./quickstart.sh faroe-islands          # Faroe Islands,europe
./quickstart.sh fiji          # Fiji,australia-oceania
./quickstart.sh finland          # Finland,europe
./quickstart.sh florida          # Florida,us
./quickstart.sh france          # France,europe
./quickstart.sh franche-comte          # Franche Comte,france
./quickstart.sh freiburg-regbez          # Regierungsbezirk Freiburg,baden-wuerttemberg
./quickstart.sh gcc-states          # GCC States,asia
./quickstart.sh georgia-eu          # Georgia (Eastern Europe),europe
./quickstart.sh georgia-us          # Georgia (US State),us
./quickstart.sh germany          # Germany,europe
./quickstart.sh gloucestershire          # Gloucestershire,england
./quickstart.sh great-britain          # Great Britain,europe
./quickstart.sh greater-london          # Greater London,england
./quickstart.sh greater-manchester          # Greater Manchester,england
./quickstart.sh greece          # Greece,europe
./quickstart.sh greenland          # Greenland,north-america
./quickstart.sh guadeloupe          # Guadeloupe,france
./quickstart.sh guatemala          # Guatemala,central-america
./quickstart.sh guinea          # Guinea,africa
./quickstart.sh guinea-bissau          # Guinea-Bissau,africa
./quickstart.sh guyane          # Guyane,france
./quickstart.sh haiti-and-domrep          # Haiti and Dominican Republic,central-america
./quickstart.sh hamburg          # Hamburg,germany
./quickstart.sh hampshire          # Hampshire,england
./quickstart.sh haute-normandie          # Haute-Normandie,france
./quickstart.sh hawaii          # Hawaii,us
./quickstart.sh herefordshire          # Herefordshire,england
./quickstart.sh hertfordshire          # Hertfordshire,england
./quickstart.sh hessen          # Hessen,germany
./quickstart.sh hungary          # Hungary,europe
./quickstart.sh iceland          # Iceland,europe
./quickstart.sh idaho          # Idaho,us
./quickstart.sh ile-de-france          # Ile-de-France,france
./quickstart.sh illinois          # Illinois,us
./quickstart.sh india          # India,asia
./quickstart.sh indiana          # Indiana,us
./quickstart.sh indonesia          # Indonesia,asia
./quickstart.sh iowa          # Iowa,us
./quickstart.sh irak          # Irak,asia
./quickstart.sh iran          # Iran,asia
./quickstart.sh ireland-and-northern-ireland          # Ireland and Northern Ireland,europe
./quickstart.sh isle-of-man          # Isle of Man,europe
./quickstart.sh isle-of-wight          # Isle of Wight,england
./quickstart.sh israel-and-palestine          # Israel and Palestine,asia
./quickstart.sh italy          # Italy,europe
./quickstart.sh ivory-coast          # Ivory Coast,africa
./quickstart.sh japan          # Japan,asia
./quickstart.sh jordan          # Jordan,asia
./quickstart.sh kansas          # Kansas,us
./quickstart.sh karlsruhe-regbez          # Regierungsbezirk Karlsruhe,baden-wuerttemberg
./quickstart.sh kazakhstan          # Kazakhstan,asia
./quickstart.sh kent          # Kent,england
./quickstart.sh kentucky          # Kentucky,us
./quickstart.sh kenya          # Kenya,africa
./quickstart.sh koeln-regbez          # Regierungsbezirk Köln,nordrhein-westfalen
./quickstart.sh kosovo          # Kosovo,europe
./quickstart.sh kyrgyzstan          # Kyrgyzstan,asia
./quickstart.sh lancashire          # Lancashire,england
./quickstart.sh languedoc-roussillon          # Languedoc-Roussillon,france
./quickstart.sh latvia          # Latvia,europe
./quickstart.sh lebanon          # Lebanon,asia
./quickstart.sh leicestershire          # Leicestershire,england
./quickstart.sh lesotho          # Lesotho,africa
./quickstart.sh liberia          # Liberia,africa
./quickstart.sh libya          # Libya,africa
./quickstart.sh liechtenstein          # Liechtenstein,europe
./quickstart.sh limousin          # Limousin,france
./quickstart.sh lithuania          # Lithuania,europe
./quickstart.sh lorraine          # Lorraine,france
./quickstart.sh louisiana          # Louisiana,us
./quickstart.sh luxembourg          # Luxembourg,europe
./quickstart.sh macedonia          # Macedonia,europe
./quickstart.sh madagascar          # Madagascar,africa
./quickstart.sh maine          # Maine,us
./quickstart.sh malaysia-singapore-brunei          # Malaysia, Singapore, and Brunei,asia
./quickstart.sh malta          # Malta,europe
./quickstart.sh manitoba          # Manitoba,canada
./quickstart.sh martinique          # Martinique,france
./quickstart.sh maryland          # Maryland,us
./quickstart.sh massachusetts          # Massachusetts,us
./quickstart.sh mayotte          # Mayotte,france
./quickstart.sh mecklenburg-vorpommern          # Mecklenburg-Vorpommern,germany
./quickstart.sh mexico          # Mexico,north-america
./quickstart.sh michigan          # Michigan,us
./quickstart.sh midi-pyrenees          # Midi-Pyrenees,france
./quickstart.sh minnesota          # Minnesota,us
./quickstart.sh mississippi          # Mississippi,us
./quickstart.sh missouri          # Missouri,us
./quickstart.sh mittelfranken          # Mittelfranken,bayern
./quickstart.sh moldova          # Moldova,europe
./quickstart.sh monaco          # Monaco,europe
./quickstart.sh mongolia          # Mongolia,asia
./quickstart.sh montana          # Montana,us
./quickstart.sh montenegro          # Montenegro,europe
./quickstart.sh morocco          # Morocco,africa
./quickstart.sh muenster-regbez          # Regierungsbezirk Münster,nordrhein-westfalen
./quickstart.sh nebraska          # Nebraska,us
./quickstart.sh nepal          # Nepal,asia
./quickstart.sh netherlands          # Netherlands,europe
./quickstart.sh nevada          # Nevada,us
./quickstart.sh new-brunswick          # New Brunswick,canada
./quickstart.sh new-caledonia          # New Caledonia,australia-oceania
./quickstart.sh new-hampshire          # New Hampshire,us
./quickstart.sh new-jersey          # New Jersey,us
./quickstart.sh new-mexico          # New Mexico,us
./quickstart.sh new-york          # New York,us
./quickstart.sh new-zealand          # New Zealand,australia-oceania
./quickstart.sh newfoundland-and-labrador          # Newfoundland and Labrador,canada
./quickstart.sh niederbayern          # Niederbayern,bayern
./quickstart.sh niedersachsen          # Niedersachsen,germany
./quickstart.sh nigeria          # Nigeria,africa
./quickstart.sh nord-pas-de-calais          # Nord-Pas-de-Calais,france
./quickstart.sh nordrhein-westfalen          # Nordrhein-Westfalen,germany
./quickstart.sh norfolk          # Norfolk,england
./quickstart.sh north-america          # North America,
./quickstart.sh north-carolina          # North Carolina,us
./quickstart.sh north-dakota          # North Dakota,us
./quickstart.sh north-korea          # North Korea,asia
./quickstart.sh north-yorkshire          # North Yorkshire,england
./quickstart.sh northwest-territories          # Northwest Territories,canada
./quickstart.sh norway          # Norway,europe
./quickstart.sh nottinghamshire          # Nottinghamshire,england
./quickstart.sh nova-scotia          # Nova Scotia,canada
./quickstart.sh nunavut          # Nunavut,canada
./quickstart.sh oberbayern          # Oberbayern,bayern
./quickstart.sh oberfranken          # Oberfranken,bayern
./quickstart.sh oberpfalz          # Oberpfalz,bayern
./quickstart.sh ohio          # Ohio,us
./quickstart.sh oklahoma          # Oklahoma,us
./quickstart.sh ontario          # Ontario,canada
./quickstart.sh oregon          # Oregon,us
./quickstart.sh oxfordshire          # Oxfordshire,england
./quickstart.sh pakistan          # Pakistan,asia
./quickstart.sh paraguay          # Paraguay,south-america
./quickstart.sh pays-de-la-loire          # Pays de la Loire,france
./quickstart.sh pennsylvania          # Pennsylvania,us
./quickstart.sh peru          # Peru,south-america
./quickstart.sh philippines          # Philippines,asia
./quickstart.sh picardie          # Picardie,france
./quickstart.sh poitou-charentes          # Poitou-Charentes,france
./quickstart.sh poland          # Poland,europe
./quickstart.sh portugal          # Portugal,europe
./quickstart.sh prince-edward-island          # Prince Edward Island,canada
./quickstart.sh provence-alpes-cote-d-azur          # Provence Alpes-Cote-d'Azur,france
./quickstart.sh quebec          # Quebec,canada
./quickstart.sh reunion          # Reunion,france
./quickstart.sh rheinland-pfalz          # Rheinland-Pfalz,germany
./quickstart.sh rhode-island          # Rhode Island,us
./quickstart.sh rhone-alpes          # Rhone-Alpes,france
./quickstart.sh romania          # Romania,europe
./quickstart.sh russia-asian-part          # Russia (Asian part),asia
./quickstart.sh russia-european-part          # Russia (European part),europe
./quickstart.sh saarland          # Saarland,germany
./quickstart.sh sachsen          # Sachsen,germany
./quickstart.sh sachsen-anhalt          # Sachsen-Anhalt,germany
./quickstart.sh saskatchewan          # Saskatchewan,canada
./quickstart.sh schleswig-holstein          # Schleswig-Holstein,germany
./quickstart.sh schwaben          # Schwaben,bayern
./quickstart.sh scotland          # Scotland,great-britain
./quickstart.sh serbia          # Serbia,europe
./quickstart.sh shropshire          # Shropshire,england
./quickstart.sh sierra-leone          # Sierra Leone,africa
./quickstart.sh slovakia          # Slovakia,europe
./quickstart.sh slovenia          # Slovenia,europe
./quickstart.sh somalia          # Somalia,africa
./quickstart.sh somerset          # Somerset,england
./quickstart.sh south-africa-and-lesotho          # South Africa (includes Lesotho),africa
./quickstart.sh south-america          # South America,
./quickstart.sh south-carolina          # South Carolina,us
./quickstart.sh south-dakota          # South Dakota,us
./quickstart.sh south-korea          # South Korea,asia
./quickstart.sh south-yorkshire          # South Yorkshire,england
./quickstart.sh spain          # Spain,europe
./quickstart.sh sri-lanka          # Sri Lanka,asia
./quickstart.sh staffordshire          # Staffordshire,england
./quickstart.sh stuttgart-regbez          # Regierungsbezirk Stuttgart,baden-wuerttemberg
./quickstart.sh suffolk          # Suffolk,england
./quickstart.sh surrey          # Surrey,england
./quickstart.sh sweden          # Sweden,europe
./quickstart.sh switzerland          # Switzerland,europe
./quickstart.sh syria          # Syria,asia
./quickstart.sh taiwan          # Taiwan,asia
./quickstart.sh tajikistan          # Tajikistan,asia
./quickstart.sh tanzania          # Tanzania,africa
./quickstart.sh tennessee          # Tennessee,us
./quickstart.sh texas          # Texas,us
./quickstart.sh thailand          # Thailand,asia
./quickstart.sh thueringen          # Thüringen,germany
./quickstart.sh tuebingen-regbez          # Regierungsbezirk Tübingen,baden-wuerttemberg
./quickstart.sh turkey          # Turkey,europe
./quickstart.sh turkmenistan          # Turkmenistan,asia
./quickstart.sh ukraine          # Ukraine,europe
./quickstart.sh unterfranken          # Unterfranken,bayern
./quickstart.sh uruguay          # Uruguay,south-america
./quickstart.sh us-midwest          # US Midwest,north-america
./quickstart.sh us-northeast          # US Northeast,north-america
./quickstart.sh us-pacific          # US Pacific,north-america
./quickstart.sh us-south          # US South,north-america
./quickstart.sh us-west          # US West,north-america
./quickstart.sh utah          # Utah,us
./quickstart.sh uzbekistan          # Uzbekistan,asia
./quickstart.sh vermont          # Vermont,us
./quickstart.sh vietnam          # Vietnam,asia
./quickstart.sh virginia          # Virginia,us
./quickstart.sh wales          # Wales,great-britain
./quickstart.sh washington          # Washington,us
./quickstart.sh west-midlands          # West Midlands,england
./quickstart.sh west-sussex          # West Sussex,england
./quickstart.sh west-virginia          # West Virginia,us
./quickstart.sh west-yorkshire          # West Yorkshire,england
./quickstart.sh wiltshire          # Wiltshire,england
./quickstart.sh wisconsin          # Wisconsin,us
./quickstart.sh wyoming          # Wyoming,us
./quickstart.sh yukon          # Yukon,canada
```
### Using your own OSM data
Mbtiles can be generated from an arbitrary osm.pbf (e.g. for a region that is not covered by an existing extract) by making the `data/` directory and placing an osm.pbf inside/

```
mkdir -p data
mv my.osm.pbf data/
./quickstart.sh my
```

### Check postserve
*  ` docker-compose up -d postserve`
and the generated maps are going to be available in browser on [localhost:8090/0/0/0.pbf](http://localhost:8090/0/0/0.pbf).

### Check tileserver

start: 
*  ` make start-tileserver` 
and the generated maps are going to be available in webbrowser on [localhost:8080](http://localhost:8080/).

This is only a quick preview, because your mbtiles only generated to zoom level 7 !  


### Change MIN_ZOOM and MAX_ZOOM

modify the settings in the `.env`  file, the defaults :
* QUICKSTART_MIN_ZOOM=0
* QUICKSTART_MAX_ZOOM=7  

and re-start  `./quickstart.sh `
*  the new config file re-generating to here  ./data/docker-compose-config.yml
*  Known problems:
    * If you use same area - then the ./data/docker-compose-config.yml not re-generating, so you have to modify by hand! 

Hints: 
* Small increments! Never starts with the MAX_ZOOM = 14
* The suggested  MAX_ZOOM = 14  - use only with small extracts

### Check other commands

`make help`


the current output:

```
==============================================================================
 OpenMapTiles  https://github.com/openmaptiles/openmaptiles 
Hints for testing areas                
  make download-geofabrik-list         # list actual geofabrik OSM extracts for download -> <<your-area>> 
  make list                            # list actual geofabrik OSM extracts for download -> <<your-area>> 
  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar 
  
Hints for designers:
  ....TODO....                         # start Maputnik 
  make start-tileserver                # start klokantech/tileserver-gl [ see localhost:8080 ] 
  make start-mapbox-studio             # start Mapbox Studio
  
Hints for developers:
  make                                 # build source code  
  make download-geofabrik area=albania # download OSM data from geofabrik, and create config file
  make psql                            # start PostgreSQL console 
  make psql-list-tables                # list all PostgreSQL tables 
  make generate-qareports              # generate reports [./build/qareports]
  make generate-devdoc                 # generate devdoc  [./build/devdoc]
  make import-sql-dev                  # start import-sql  /bin/bash terminal 
  make import-osm-dev                  # start import-osm  /bin/bash terminal (imposm3)
  make clean-docker                    # remove docker containers, PG data volume 
  make forced-clean-sql                # drop all PostgreSQL tables for clean environment 
  make docker-unnecessary-clean        # clean unnecessary docker image(s) and container(s)
  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB
  make remove-docker-images            # remove openmaptiles docker images
  make pgclimb-list-views              # list PostgreSQL public schema views
  make pgclimb-list-tables             # list PostgreSQL public schema tabless
  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM informations
  cat ./quickstart.log                 # backup  of the last ./quickstart.sh 
  make help                            # help about avaialable commands
==============================================================================
```
 
