/*
	1. Dane pobrane ze strony: https://osdatahub.os.uk/downloads/open
	2. Ładowanie danych za pomocą raster2pgsql
	3. W OSGeo4W:
gdalbuildvrt UK_250k.vrt *.tif

gdal_translate UK_250k.vrt UK_250k_mosaic.tif
	4. Dane pobrane w formacie gpkg ze strony: https://osdatahub.os.uk/downloads/open/OpenZoomstack
	5. ogr2ogr -f "PostgreSQL" "PG:dbname=cw7 user=postgres host=localhost password=*" OS_Open_Zoomstack.gpkg "national_parks" -nln nat_parks
*/
--6
CREATE TABLE uk_lake_district AS
SELECT ST_Union(ST_Clip(r.rast, (SELECT geom FROM nat_parks WHERE id = 1))) AS rast
FROM uk_250k_final r
WHERE ST_Intersects(r.rast, (SELECT geom FROM nat_parks WHERE id = 1));
/*
	7. W OSGeo4W:
gdal_translate -of GTiff -ot Byte -co "COMPRESS=DEFLATE" -co "PREDICTOR=2" -co "ZLEVEL=9" PG:"host=localhost port=5432 dbname=cw7 user=postgres password=* schema=public table=uk_lake_district mode=2" uk_lake_district.tif

	8. Dane wybranie z strony (2 kafle)

	9. Wszystkie 4 kafle odpowiednich pasm (3 i 8) zaimportowane w podny sposób:
	 raster2pgsql -s 32630 -c -I -C -M "C:\Users\Gosia\OneDrive\Dokumenty\aa studia\BDP\cw8\T30UWF_B08.jp2" public.sent_b8_tile2 | psql -h localhost -p 5432 -U postgres -d cw7
*/
--10 
DROP TABLE IF EXISTS b3_mosaic;
CREATE TABLE b3_mosaic AS 
SELECT ST_Union(rast) as rast
FROM(
	SELECT rast FROM public.sent_b3_tile1
	UNION ALL
	SELECT rast FROM public.sent_b3_tile2
) AS b3

DROP TABLE IF EXISTS b8_mosaic;
CREATE TABLE b8_mosaic AS 
SELECT ST_Union(rast) as rast
FROM(
	SELECT rast FROM public.sent_b8_tile1
	UNION ALL
	SELECT rast FROM public.sent_b8_tile2
) AS b8

CREATE TABLE public.ndwi AS
SELECT
    1 AS rid, 
    ST_MapAlgebra(
        r1.rast,
        r2.rast,
        'CASE 
            WHEN ([rast1] + [rast2]) = 0 THEN NULL
            ELSE ([rast1] - [rast2]) / ([rast1] + [rast2])
         END',
        '32BF'
    ) AS rast
FROM 
    public.b3_mosaic AS r1, 
    public.b8_mosaic AS r2
WHERE ST_Intersects(r1.rast, r2.rast);

CREATE TABLE ndwi_lake_clip AS
SELECT ST_Clip(ndwi.rast, ST_Transform((SELECT geom FROM public.nat_parks WHERE id=1), ST_SRID(ndwi.rast))) AS rast
FROM public.ndwi AS ndwi;
	
SELECT *
FROM public.sent_b8_tile1

/*
	11. gdal_translate -of GTiff -ot Float32 -co "COMPRESS=DEFLATE" -co "ZLEVEL=9" PG:"host=localhost port=5432 dbname=cw7 user=postgres password=2557 schema=public table=ndwi_lake_clip mode=2" "C:\Users\Gosia\OneDrive\Dokumenty\aa studia\BDP\cw8\ndwi_lake_clip.tif"
*/
