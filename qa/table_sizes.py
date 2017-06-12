#!/usr/bin/env python
import sys
import argparse
import subprocess

parser  = argparse.ArgumentParser()
parser.add_argument('--noan', action='store_true', help='Not to run make psql-analyze')


TOTAL_SIZE_SQL = """SELECT
  pg_size_pretty(sum(size)) AS size
FROM (
  SELECT
    relname as "Table",
    pg_total_relation_size(relid) as "size"
  FROM pg_catalog.pg_statio_user_tables
  WHERE schemaname='public'
) a
;""".replace('\"', '\\\"')


TABLE_SIZES_SQL="""SELECT
  a.relname as "table",
  pg_table_size(a.relid) as "size",
  b.n_live_tup as "rows"
FROM pg_catalog.pg_statio_user_tables a
  LEFT JOIN pg_stat_user_tables b ON (a.relid = b.relid)
WHERE
  a.schemaname='public'
ORDER BY a.relname;
""".replace('\"', '\\\"')


TABLES_SQL = """SELECT
  a.relname
FROM pg_catalog.pg_statio_user_tables a
WHERE
  a.schemaname='public'
ORDER BY a.relname;
"""

COLUMN_NAMES_SQL = """SELECT a.attname
FROM pg_class As c
  INNER JOIN pg_attribute As a ON c.oid = a.attrelid
  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE
  c.relkind IN('r', 'v', 'm') AND
  a.attnum > 0 AND
  n.nspname = 'public' AND
  c.relname = '{0}' AND
  a.attisdropped = FALSE
ORDER BY a.attname;
"""

COLUMNS_SQL = """select
    sum(pg_column_size(t.*)) as "all",
    {0}
from {1} t;
""".replace('\"', '\\\"')

def print_column_sizes(tables):
    for table in tables:
        print "Column sizes of table "+table
        cmds = [
            'docker-compose run --rm import-osm',
            '/usr/src/app/psql.sh -t -A -F\",\" -P pager=off',
            '-c \"' + COLUMN_NAMES_SQL.format(table).replace('\n', ' ').replace('\r', '') + '\"'
        ]
        # print " ".join(cmds)
        output = subprocess.check_output(" ".join(cmds), shell=True)
        columns = filter(lambda c: len(c)>0, map(lambda l: l.strip(), output.split('\n')))

        # print columns

        col_sql = ",\n".join(map(lambda c: "sum(pg_column_size(\\\""+c+"\\\")) as \\\""+c+"\\\"", columns))

        # print COLUMNS_SQL.format(col_sql, table);

        cmds = [
            'docker-compose run --rm import-osm',
            '/usr/src/app/psql.sh -F\",\" --no-align -P pager=off',
            '-c \"' + COLUMNS_SQL.format(col_sql, table).replace('\n', ' ').replace('\r', '') + '\"'
        ]
        # print " ".join(cmds)
        col_csv = subprocess.check_output(" ".join(cmds), shell=True)
        print col_csv




if __name__ == "__main__":
    args = parser.parse_args()

    try:

        if(not args.noan):
            print "Running make psql-analyze"
            subprocess.check_output("make psql-analyze", shell=True)


        print "Total size of tables"
        cmds = [
            'docker-compose run --rm import-osm',
            '/usr/src/app/psql.sh -F\",\" --no-align -P pager=off',
            '-c \"' + TOTAL_SIZE_SQL.replace('\n', ' ').replace('\r', '') + '\"'
        ]
        # print " ".join(cmds)
        TOTAL_SIZE_CSV = subprocess.check_output(" ".join(cmds), shell=True)
        print TOTAL_SIZE_CSV
        print "\n"


        print "Table sizes"
        cmds = [
            'docker-compose run --rm import-osm',
            '/usr/src/app/psql.sh -F\",\" --no-align -P pager=off',
            '-c \"' + TABLE_SIZES_SQL.replace('\n', ' ').replace('\r', '') + '\"'
        ]
        # print " ".join(cmds)
        TABLE_SIZES_CSV = subprocess.check_output(" ".join(cmds), shell=True)
        print TABLE_SIZES_CSV
        print "\n"


        print "Column sizes"
        cmds = [
            'docker-compose run --rm import-osm',
            '/usr/src/app/psql.sh -t -A -F\",\" -P pager=off',
            '-c \"' + TABLES_SQL.replace('\n', ' ').replace('\r', '') + '\"'
        ]
        # print " ".join(cmds)
        output = subprocess.check_output(" ".join(cmds), shell=True)
        tables = filter(lambda t: len(t)>0, map(lambda l: l.strip(), output.split('\n')))

        print_column_sizes(tables);

        # print tables
    except subprocess.CalledProcessError, e:
        print "Error:\n", e.output
    sys.exit(0)
