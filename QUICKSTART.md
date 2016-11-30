

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
* docker         >=1.10
    * https://www.docker.com/products/overview
* docker-compose >=1.7.1
    * https://docs.docker.com/compose/install/
* disk space ( >= ~15Gb  )
    * for small extracts  >= ~15Gb
    * for big extracts ( continents, planet) > 20 ... 1000 Gb
    * And depends on
        * OpenStreetMap data size
        * Zoom level
* memory ( >= 3Gb )
    * for small extracts 3Gb-8Gb RAM
    * for big extracts ( Europe, Planet) > 8-32 Gb
* internet connections
    * for downloading docker images
    * for downloading OpenStreetMap data from Geofabrik

Important:  The ./quickstart.sh is for small extracts - not optimal for a Planet rendering !!

### First experiment - with albania ( small extracts! )

```bash
git clone https://github.com/openmaptiles/openmaptiles.git
cd openmaptiles
./quickstart.sh
```

If you have problems with the quickstart
* check the ./quickstart.log!
* check again the system requirements
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
THAN you can test other available quickstart extracts ( based on geofabrik extracts) !
 * We are using https://github.com/julien-noblet/download-geofabrik tool
 * The current extract list, and more informations  ->  `make list`

This is generating mbtiles for your area :  [ MIN_ZOOM: "0"  - MAX_ZOOM: "7" ]

```bash
./quickstart.sh africa
./quickstart.sh alabama
./quickstart.sh alaska
./quickstart.sh albania
./quickstart.sh alberta
./quickstart.sh alps
./quickstart.sh alsace
./quickstart.sh andorra
./quickstart.sh antarctica
./quickstart.sh aquitaine
./quickstart.sh argentina
./quickstart.sh arizona
./quickstart.sh arkansas
./quickstart.sh asia
./quickstart.sh australia
./quickstart.sh austria
./quickstart.sh auvergne
./quickstart.sh azerbaijan
./quickstart.sh azores
./quickstart.sh bangladesh
./quickstart.sh bayern
./quickstart.sh belarus
./quickstart.sh belgium
./quickstart.sh belize
./quickstart.sh berlin
./quickstart.sh bolivia
./quickstart.sh botswana
./quickstart.sh bourgogne
./quickstart.sh brandenburg
./quickstart.sh brazil
./quickstart.sh bremen
./quickstart.sh bretagne
./quickstart.sh buckinghamshire
./quickstart.sh bulgaria
./quickstart.sh california
./quickstart.sh cambridgeshire
./quickstart.sh cameroon
./quickstart.sh canada
./quickstart.sh centre
./quickstart.sh cheshire
./quickstart.sh chile
./quickstart.sh china
./quickstart.sh colombia
./quickstart.sh colorado
./quickstart.sh connecticut
./quickstart.sh cornwall
./quickstart.sh corse
./quickstart.sh croatia
./quickstart.sh cuba
./quickstart.sh cumbria
./quickstart.sh cyprus
./quickstart.sh dach
./quickstart.sh delaware
./quickstart.sh denmark
./quickstart.sh derbyshire
./quickstart.sh devon
./quickstart.sh dorset
./quickstart.sh ecuador
./quickstart.sh egypt
./quickstart.sh england
./quickstart.sh essex
./quickstart.sh estonia
./quickstart.sh ethiopia
./quickstart.sh europe
./quickstart.sh fiji
./quickstart.sh finland
./quickstart.sh florida
./quickstart.sh france
./quickstart.sh germany
./quickstart.sh gloucestershire
./quickstart.sh greece
./quickstart.sh greenland
./quickstart.sh guadeloupe
./quickstart.sh guatemala
./quickstart.sh guinea
./quickstart.sh guyane
./quickstart.sh hamburg
./quickstart.sh hampshire
./quickstart.sh hawaii
./quickstart.sh herefordshire
./quickstart.sh hertfordshire
./quickstart.sh hessen
./quickstart.sh hungary
./quickstart.sh iceland
./quickstart.sh idaho
./quickstart.sh illinois
./quickstart.sh india
./quickstart.sh indiana
./quickstart.sh indonesia
./quickstart.sh iowa
./quickstart.sh irak
./quickstart.sh iran
./quickstart.sh italy
./quickstart.sh japan
./quickstart.sh jordan
./quickstart.sh kansas
./quickstart.sh kazakhstan
./quickstart.sh kent
./quickstart.sh kentucky
./quickstart.sh kenya
./quickstart.sh kosovo
./quickstart.sh kyrgyzstan
./quickstart.sh lancashire
./quickstart.sh latvia
./quickstart.sh lebanon
./quickstart.sh leicestershire
./quickstart.sh lesotho
./quickstart.sh liberia
./quickstart.sh libya
./quickstart.sh liechtenstein
./quickstart.sh limousin
./quickstart.sh lithuania
./quickstart.sh lorraine
./quickstart.sh louisiana
./quickstart.sh luxembourg
./quickstart.sh macedonia
./quickstart.sh madagascar
./quickstart.sh maine
./quickstart.sh malta
./quickstart.sh manitoba
./quickstart.sh martinique
./quickstart.sh maryland
./quickstart.sh massachusetts
./quickstart.sh mayotte
./quickstart.sh mexico
./quickstart.sh michigan
./quickstart.sh minnesota
./quickstart.sh mississippi
./quickstart.sh missouri
./quickstart.sh mittelfranken
./quickstart.sh moldova
./quickstart.sh monaco
./quickstart.sh mongolia
./quickstart.sh montana
./quickstart.sh montenegro
./quickstart.sh morocco
./quickstart.sh nebraska
./quickstart.sh nepal
./quickstart.sh netherlands
./quickstart.sh nevada
./quickstart.sh niederbayern
./quickstart.sh niedersachsen
./quickstart.sh nigeria
./quickstart.sh norfolk
./quickstart.sh norway
./quickstart.sh nottinghamshire
./quickstart.sh nunavut
./quickstart.sh oberbayern
./quickstart.sh oberfranken
./quickstart.sh oberpfalz
./quickstart.sh ohio
./quickstart.sh oklahoma
./quickstart.sh ontario
./quickstart.sh oregon
./quickstart.sh oxfordshire
./quickstart.sh pakistan
./quickstart.sh paraguay
./quickstart.sh pennsylvania
./quickstart.sh peru
./quickstart.sh philippines
./quickstart.sh picardie
./quickstart.sh poland
./quickstart.sh portugal
./quickstart.sh quebec
./quickstart.sh reunion
./quickstart.sh romania
./quickstart.sh saarland
./quickstart.sh sachsen
./quickstart.sh saskatchewan
./quickstart.sh schwaben
./quickstart.sh scotland
./quickstart.sh serbia
./quickstart.sh shropshire
./quickstart.sh slovakia
./quickstart.sh slovenia
./quickstart.sh somalia
./quickstart.sh somerset
./quickstart.sh spain
./quickstart.sh staffordshire
./quickstart.sh suffolk
./quickstart.sh surrey
./quickstart.sh sweden
./quickstart.sh switzerland
./quickstart.sh syria
./quickstart.sh taiwan
./quickstart.sh tajikistan
./quickstart.sh tanzania
./quickstart.sh tennessee
./quickstart.sh texas
./quickstart.sh thailand
./quickstart.sh thueringen
./quickstart.sh turkey
./quickstart.sh turkmenistan
./quickstart.sh ukraine
./quickstart.sh unterfranken
./quickstart.sh uruguay
./quickstart.sh us
./quickstart.sh utah
./quickstart.sh uzbekistan
./quickstart.sh vermont
./quickstart.sh vietnam
./quickstart.sh virginia
./quickstart.sh wales
./quickstart.sh washington
./quickstart.sh wiltshire
./quickstart.sh wisconsin
./quickstart.sh wyoming
./quickstart.sh yukon
```

### Check other commands

`make help`


### Change MIN_ZOOM and MAX_ZOOM

modify the settings in the `.env`  file
* QUICKSTART_MIN_ZOOM=0
* QUICKSTART_MAX_ZOOM=7  

and re-start  `./quickstart.sh `
*  the new config file re-generating to here  ./data/docker-compose-config.yml
*  Known problems:
    * If you use same area - then the ./data/docker-compose-config.yml not re-generating, so you have to modify by hand! 

Hints: 
* Small increments! Never starts with the MAX_ZOOM = 14
* The suggested  MAX_ZOOM = 14  - use only with small extracts

