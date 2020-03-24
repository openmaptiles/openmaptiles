#!/usr/bin/env bash
set -euo pipefail

#
# Download several areas, combine them into a single file, and print --bbox params needed to run test-perf
#

# List of Geofabrik areas
TEST_AREAS=(equatorial-guinea liechtenstein district-of-columbia greater-london)

: "${DATA_DIR:=/tileset/data/test}"
: "${DATA_FILE_SUFFIX:=-latest.osm.pbf}"
: "${RESULT_FILE:=test${DATA_FILE_SUFFIX}}"

mkdir -p "$DATA_DIR"
cd "$DATA_DIR"


echo -e $"\n=========== downloading areas" "${TEST_AREAS[@]}" "==========================="
for area in "${TEST_AREAS[@]}"; do
  file="${area}${DATA_FILE_SUFFIX}"
  if [ -f "$file" ]; then
    echo "File $file already exists, skipping download"
  else
    download-osm geofabrik "${area}" -- -d "$DATA_DIR"
    if [ ! -f "$file" ]; then
      echo "Unexpected error while downloading $file, aborting"
      exit 1
    fi
  fi
done


echo -e $"\n=========== Merging" "${TEST_AREAS[@]}" "into ${RESULT_FILE} ====="
rm -f "${RESULT_FILE}"
OSMOSIS_ARG="--read-pbf ${TEST_AREAS[0]}${DATA_FILE_SUFFIX} $(printf " --read-pbf %s${DATA_FILE_SUFFIX} --merge" "${TEST_AREAS[@]:1}")"
# shellcheck disable=SC2086
( set -x; osmosis ${OSMOSIS_ARG} --write-pbf "${RESULT_FILE}" )


echo -e $"\n=========== Computing test BBOXes ======================="
echo -e $"\n  File ${RESULT_FILE} ($(du -b "$RESULT_FILE" | cut -f1)) has been generated with these test areas:\n"
for area in "${TEST_AREAS[@]}"; do
  file="${area}${DATA_FILE_SUFFIX}"
  STATS=$(osmconvert --out-statistics "$file" )
  LON_MIN=$( echo "$STATS" | grep "lon min:" | cut -d":" -f 2 | awk '{gsub(/^ +| +$/,"")} {print $0}' )
  LON_MAX=$( echo "$STATS" | grep "lon max:" | cut -d":" -f 2 | awk '{gsub(/^ +| +$/,"")} {print $0}' )
  LAT_MIN=$( echo "$STATS" | grep "lat min:" | cut -d":" -f 2 | awk '{gsub(/^ +| +$/,"")} {print $0}' )
  LAT_MAX=$( echo "$STATS" | grep "lat max:" | cut -d":" -f 2 | awk '{gsub(/^ +| +$/,"")} {print $0}' )
  BBOX="${LON_MIN},${LAT_MIN},${LON_MAX},${LAT_MAX}"
  FILE_SIZE="$(du -b "$file" | cut -f1)"

  cat <<EOF | (PYTHONPATH=/usr/src/app python)
from openmaptiles.perfutils import TestCase
tc = TestCase('${area}', 'a', bbox='${BBOX}')
info = f"# {tc.id} {tc.size():,} tiles at z14, \
{$FILE_SIZE/1024/1024:,.1f}MB, {$FILE_SIZE/tc.size():,.1f} bytes/tile \
[{tc.start[0]}/{tc.start[1]}]x[{tc.before[0] - 1}/{tc.before[1] - 1}]"
print(f"  --bbox {tc.bbox:46} {info}")
EOF
done
echo ""
