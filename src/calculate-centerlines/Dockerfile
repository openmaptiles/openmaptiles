FROM debian:buster-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      gdal-bin \
      libgdal-dev \
      python \
      python-pip \
      python-dev \
      python-gdal \
      git \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
      python-scipy \
      python-setuptools \
      python-shapely \
    && rm -rf /var/lib/apt/lists/*

#WORKDIR /usr/src/app
#RUN git clone https://github.com/ungarj/label_centerlines.git /usr/src/app

RUN pip install wheel
RUN pip install networkx Fiona

COPY *.py /
CMD ["./create_centerlines.py", "--output_driver", "GeoJSON", "/data/osm_lake_polygon.shp", "/data/osm_lake_centerline.geojson"]
