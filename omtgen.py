#!/usr/bin/env python
"""
Usage:
  omtgen tm2source <tileset> [--host=<host>] [--port=<port>] [--database=<dbname>] [--user=<user>] [--password=<pw>]
  omtgen --help
  omtgen --version
Options:
  --help              Show this screen.
  --version           Show version.
  --host=<host>       PostGIS host.
  --port=<port>       PostGIS port.
  --database=<dbname> PostGIS database name.
  --user=<user>       PostGIS user.
  --password=<pw>     PostGIS password.
"""
import sys
import yaml
import collections
from docopt import docopt

DbParams = collections.namedtuple('DbParams', ['dbname', 'host', 'port',
                                               'password', 'user'])


def generate_layer(layer_def, db_params):
    layer = layer_def['layer']
    datasource = layer['datasource']
    tm2layer = {
        'id': layer['id'],
        'description': layer['description'],
        'srs': layer['srs'],
        'properties': {
            'buffer-size': layer['buffer_size']
        },
        'fields': layer['fields'],
        'Datasource': {
          'extent': [-20037508.34, -20037508.34, 20037508.34, 20037508.34],
          'geometry_field': datasource.get('geometry_field', 'geom'),
          'key_field': datasource.get('key_field', ''),
          'key_field_as_attribute': datasource.get('key_field_as_attribute', ''),
          'max_size': datasource.get('max_size', 512),
          'port': db_params.port,
          'srid': datasource['srid'],
          'table': datasource['query'],
          'type': 'postgis',
          'host': db_params.host,
          'dbname': db_params.dbname,
          'user': db_params.user,
          'password': db_params.password,
        }
    }
    return tm2layer


def generate_tm2source(tileset_filename, db_params):
    with open(tileset_filename, 'r') as stream:
        try:
            tileset = yaml.load(stream)['tileset']
        except yaml.YAMLError as e:
            print('Could not parse ' + tileset_filename)
            print(e)
            sys.exit(403)

    tm2 = {
        'attribution': tileset['attribution'],
        'center': tileset['center'],
        'description': tileset['description'],
        'maxzoom': tileset['maxzoom'],
        'minzoom': tileset['minzoom'],
        'name': tileset['name'],
        'Layer': [],
    }

    for layer_filename in tileset['layers']:
        with open(layer_filename, 'r') as stream:
            try:
                layer_def = yaml.load(stream)
                tm2layer = generate_layer(layer_def, db_params)
                tm2['Layer'].append(tm2layer)
            except yaml.YAMLError as e:
                print('Could not parse ' + layer_filename)
                print(e)
                sys.exit(403)

    return tm2

if __name__ == '__main__':
    args = docopt(__doc__, version=0.1)
    if args.get('tm2source'):
        db_params = DbParams(
            dbname=args['--database'],
            port=int(args['--port']),
            user=args['--user'],
            password=args['--password'],
            host=args['--host']
        )
        tm2 = generate_tm2source(args['<tileset>'], db_params)
        print(yaml.dump(tm2))
