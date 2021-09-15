FROM postgis/postgis:9.6-2.5-alpine
RUN apk add libintl
COPY export-shapefile.sh /
CMD ["./export-shapefile.sh"]
