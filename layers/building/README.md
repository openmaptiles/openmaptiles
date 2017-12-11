## building

### Docs
Read the layer documentation at **http://openmaptiles.org/schema#building**

### Mapping Diagram
![Mapping diagram for building](mapping_diagram.png?raw=true)

### ETL diagram
![ETL diagram for building](etl_diagram.png?raw=true)

# Difference for qwant style
The buildings are loaded from zoom 14 because it's the lowest zoom level.
We also deactived the building height because we don't want the 3D rendering and it add more weight to the tiles and the generation times is greater.
