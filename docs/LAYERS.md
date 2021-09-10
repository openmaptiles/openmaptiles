# OpenMapTiles - Schema & Layer explanation  
OpenMapTiles is an extensible and open vector tile schema for a OpenStreetMap basemap. It is used to generate vector tiles for [openmaptiles.org](https://openmaptiles.org/).    
        
- :link: Docs https://openmaptiles.org/docs    
- :link: Schema: https://openmaptiles.org/schema    
- :link: Production package: https://openmaptiles.com/
- :link: Openmaptiles Github: https://github.com/openmaptiles/openmaptiles

## Generate tiles with custom layers

1. Download the [openmaptiles](https://github.com/openmaptiles/openmaptiles) main project.
2. Go into the `openmaptiles` directory
3. Add the layer to the `openmaptiles.yaml` [more](Add the layer to the Tileset).
4. Execute make commands:
    ```
    make clean                  # Remove the build directory
    make                        # Generate sql out of the layers
    make import-osm             # Import OSM Data into the tables they are defined in mapping.yaml
    make import-sql             # Import SQL functions from the <layer>.sql (park.sql)
    make generate-tiles-pg      # Generate .mbtiles file
    ``` 
5. Start your [Tileserver](https://openmaptiles.org/docs/host/tileserver-gl/). 
    ```
    make start-tileserver
    ```
    And go to `localhost:8090`
6. **Optional** for better developing, start a [Maputnik](https://openmaptiles.org/docs/style/maputnik/) server to check the layers data in the **Inspect** mode.
    ```
    make start-maputnik
    ```
    Which is available over the PORT `8088`: `localhost:8088`

For the complete workflow to generate tiles with the earth data and wikidata look into this: [Workflow to generate tiles](https://github.com/openmaptiles/openmaptiles#workflow-to-generate-tiles)


TODO: Explain how to connect maputnik with the local tiles. Is this needed?

## Layer structure    

TODO: A good sample project is needed

To explain the structure, the sample **park** is used.  
The following layers are childs of the folder **park**:  
  
| File name | Description |  
| --- | --- |  
| park.yaml | Start point / General definition file. Contains `description`, `fields`, `buffer_size`, `schema`, `datasources`, ...  |  
| mapping.yaml | [Imposm3 mapping file](https://imposm.org/docs/imposm3/latest/mapping.html). Definition how and where the OSM Data schould be stored in the Database. |  
| park.sql | Creates SQL functions to get the correct data from the database while tile-generation |  
  
**Optional:**  
  
| File name | Description |  
| --- | --- |  
| etl_diagram.png | TODO: EXPLAIN ME |  
| mapping_diagram.png | TODO: EXPLAIN ME |  
| update_park_polygon.sql | TODO: EXPLAIN ME |  
  
  
### park.yaml  
  
> Start point / General definition file.  
  
Sturture and fields of the file:  
  
|  |  |  | Description | Sample Data |  
| --- | --- | --- | --- | --- |  
| layer | |  | Layer properties |  
| | id | | Unique id / name of the layer | park |  
| | buffer_size |  | TODO: EXPLAIN ME | 4 |  
| | fields | | Fields that are exportet while tile-generation |  
| | | `fieldname` | Can be any char-sequence f.ex. `class`, `type`, ... The value of the fieldname can be a description string or an object with `description` and / or `values`. With passing an object, sql can be generated out it. [generate-sql](#generate-sql) | class |  
| | datasource | | Definition from where |  
| | | geometry_field | Which of the return fields are the geometry field | geometry |  
| | | query | The query which calls the layer function which takes the bounding box and the zoom level. All columns of the `SELECT`-Satement needs to be defined in the `fields`. Only the `geometry` columns don't need to be defined, because of `geometry_field`. **TODO: POSSIBLE FIELDS FOR THE QUERY** | query: (SELECT geometry, class FROM layer_park(!bbox!, z(!scale_denominator!)) AS t  
| schema | | | List (`-`) of SQL files for writing the necessary queries for your layer or create generalized tables | | | - `sqlfilepath` | | Path to the sql file. Relative paths are working too | - ./park.sql |  
| datasources | | | From where should the data parsed | |  
| | - type | | TODO: Are there different types possible? | imposm3 |  
| | mapping_file | | File where the mapping of the data is defined. It defines from where the data are mapped and into which table & columns they are imported. | ./mapping.yaml |  
  
:warning: 

> All columns of the SELECT-Satement needs to be defined in the fields section. Only the geometry columns don't need to be defined, because of geometry_field.

If a layer SQL files contains `%%FIELD_MAPPING: class%%`, `generate-sql` script will replace it

TODO: is `generate-sql` the correct one?

```sql
SELECT CASE
    %%FIELD_MAPPING: class%%
END, ...
```
into
```sql
SELECT CASE
    WHEN "subclass" IN ('school', 'kindergarten')
        OR "subclass" LIKE 'uni%' THEN 'school'
    WHEN ("subclass" = 'station' AND "mapping_key" = 'railway')
        OR "subclass" in ('halt','tram_stop','subway') THEN 'railway'
END, ...
```

Sample:  
```yaml
layer:    
  id: "park"    
  description: |    
      Custom description. The park layer contains parks from OpenStreetMap tagged with    [`boundary=national_park`](http://wiki.openstreetmap.org/wiki/Tag:boundary%3Dnational_park), ... 
  buffer_size: 4 fields:    
  class:
    description: Defines a subclass of a park
    values:
      school:
        # subclass IN ('school','kindergarten') OR subclass LIKE 'uni%'
        subclass: ['school','kindergarten','uni%']
      railway:
        # (subclass='station' AND mapping_key='railway')
        # OR subclass in ('halt','tram_stop','subway')
        - __AND__:
          subclass: 'station'
          mapping_key: 'railway'
        - subclass: ['halt', 'tram_stop', 'subway']
  datasource:    
    geometry_field: geometry    
    query: (SELECT geometry, class, name, name_en, name_de, rank FROM layer_park(!bbox!, z(!scale_denominator!))) AS t 
  schema:    
    - ./update_park_polygon.sql    
    - ./park.sql
  datasources:    
    - type: imposm3    
    mapping_file: ./mapping.yaml  
```

### mapping.yaml

> [imposm3 mapping file](https://imposm.org/docs/imposm3/latest/mapping.html) to choose the OSM data you need.


|  |  |  |  |   | Description | Sample Data |
| --- | --- | --- | --- | --- | --- | --- |
| tables |  | | | | Each [table](https://imposm.org/docs/imposm3/latest/mapping.html#tables) is a YAML object with the table name as the key. Each table has a `type`, a `mapping` definition and `columns`. | |
| | `tablename`| | | | Imposm will generate a table with the prefix `osm_`and this name `osm_park_polygon`. We encourage to use the format `layername`_`type` | park_polygon, waterway_linestring |
| | | type | | | Possible [types](https://imposm.org/docs/imposm3/latest/mapping.html#type): `point`, `linestring`, `polygon`, `geometry`, `relation` and `relation_member`. | polygon |
| | | columns | |  | List of [columns](https://imposm.org/docs/imposm3/latest/mapping.html#columns) that Imposm should create for this table. Each column is a YAML object with a `name` and a `type` and optionally `key`, `args` and `from_member`. 
| | | | name | | Name of the Column | name_en |
| | | | type |  |Column data type. There are two classes of types: [Value types](https://imposm.org/docs/imposm3/latest/mapping.html#value-types) types that convert OSM tag values to a database type. And [Element types](https://imposm.org/docs/imposm3/latest/mapping.html#element-types) they dependent on the OSM element (node/way/relation). The most used types are: Value types: `string`, `bool`, `interger`. Element types: `id`, `geometry`, `hstore_tags`, `validated_geometry` | string | 
| | | | key | | Defines the OSM key that should be used for this column. This is required for all `value types`. | name:en |
| | | | args | | Some column types require additional arguments. Refer to the documentation of the type. **TODO: Never used** | |
| | | | from_member | |  Only valid for tables of the type `relation_member`. If this is set to `true`, then tags will be used from the member instead of the relation. | |
| | | mapping | | | Defines which OSM data are used for [mapping](https://imposm.org/docs/imposm3/latest/mapping.html#mapping) and imported into the table. Childs are OSM keys with the possible OSM values. |
| | | | `OSM_key_name` | | The OSM Key is used as name and contains all possible OSM values as array or as list. To match all values use `__any__`. |  `natural: [wood, land]` or `tourism: [__any__]` |
| | | filters | | | You can limit which elements should be inserted into a table with [filters](https://imposm.org/docs/imposm3/latest/mapping.html#filters). You can only filter tags that are referenced in the `mapping` or `columns`. | |
| | | |  `require` / `require_regexp` / `reject` / `reject_regexp` | | You can require or reject  elements that have specific tag. Regex should be enclosed in single quotes (`'`). |
| | | | | `OSM_key_name` | The OSM Key is used as name and contains all required or rejected OSM values as array or as list. To get / reject all elements they have the tag use `__any__`. |  `natural: [wood, land]` or `tourism: [__any__]` |
| | | _resolve_wikidata |  | | TODO: WHAT IS THIS? | |


TODO: When is `mapping: ` and when `type_mappings:` needed

Sample:
https://imposm.org/docs/imposm3/latest/mapping.html#example
or:
```yaml  
tables:  
  # etldoc: imposm3 -> osm_park_polygon  
  park_polygon:  
    type: polygon  
    _resolve_wikidata: false  
    columns:  
    - name: osm_id  
      type: id  
    - name: geometry  
      type: geometry
    - name: name  
      key: name  
      type: string   
    - name: leisure  
      key: leisure  
      type: string  
    - name: boundary  
      key: boundary  
      type: string  
    - name: area  
      type: area  
    mapping:  
      leisure:  
      - nature_reserve  
      boundary:  
      - national_park  
      - protected_area
```

### park.sql

> Creates SQL functions to get the correct data from the database while tile-generation

```sql
CREATE OR REPLACE FUNCTION layer_hydranten(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, type text, class text) AS $$
    SELECT geometry, type, CAST('fire_hydrant' as text)
    FROM osm_hydranten_point
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
```

TODO: When is used IMMUTABLE and when others like STABLE PARALLEL SAFE;


TODO: Explain most used SQL functions like `st_centroid`, `ST_NPoints`, `ST_Area`, `ST_Dump`, `ST_Union`, `ST_MakeValid`, `ST_Simplify`, ...

### update_park_polygon.sql

TODO: Explain why it is useful to have a extra sql file


### Add the layer to the Tileset

In the `openmaptiles` project you need to change the file `openmaptiles.yaml`.
Add the new layer to  `layers`:
```yaml
tileset:
  layers:
    - layers/park/park.yaml
```

## Generate Diagrams
TODO: How is this working
Maybe with `make generate-devdoc`?

## Error handling


> ERROR:  relation "osm_YOURTABLE_polygon" does not exist.

**Script:** `make` TODO: Check

**Solution:** You need to check if you have set the table correct in your `.sql` file and in your `mapping.yaml` file. Don't forget that in the `mapping.yaml` you need to set the table without `osm_`.

----

> ERROR:  cannot change return type of existing function

**Script:** `make import-sql`

**Solution:** You need to recreate your DB with `destroy-db` or drop the function

----

> [Makefile:257: build/openmaptiles.tm2source/data.yml] Error 1

**Script:** `make`

**Solution:** Some of the layers / schemas are not valid. Comment out the layers in openmaptiles.yaml and find out which one throws the error.

----

>   File "/usr/src/app/import-wikidata", line 222, in find_tables
      for table_name, table_def in mapping['tables'].items():
  KeyError: 'tables'

**Script:** `make import-wikidata`

**Solution:** In the <layer>.yaml file the `mapping_file` value is not correct or the `mapping.yaml` has not the attribute `tables`

----

>   ValueError: Declared fields in layer 'skiing' do not match the fields received from a query: These fields were returned by the query, but not declared: name

**Script:** `make import-sql`

**Solution:** In the <layer>.yaml file the `mapping_file` value is not correct or the `mapping.yaml` has not the attribute `tables`



