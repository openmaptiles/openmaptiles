FROM python:3.8-slim-buster

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ungarj/label_centerlines.git
COPY *.py ./label_centerlines

WORKDIR ./label_centerlines
RUN pip install -r requirements.txt
RUN python setup.py install

CMD ["./calculate_centerlines.py", "--output_driver", "GeoJSON", "/data/osm_lake_polygon.shp", "/data/osm_lake_centerline.geojson"]
#CMD ["./create_centerlines.py", "--output_driver", "GeoJSON", "/data/osm_lake_polygon.shp", "/data/osm_lake_centerline.geojson"]
