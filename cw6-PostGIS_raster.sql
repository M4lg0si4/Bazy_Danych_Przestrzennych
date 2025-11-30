--Tworzenie rastrów z istniejących rastrów i interakcja z wektorami
--1 ST_Intersect

CREATE TABLE koper.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table koper.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON koper.intersects
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('koper'::name,
'intersects'::name,'rast'::name);

select *
from koper.intersects

--2 Obcianie
CREATE TABLE koper.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

-- 3 UNION

CREATE TABLE koper.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--Tworzenie rastrów z wektorów (rastrowanie)
--1 ST_Raster
CREATE TABLE koper.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 2 St_union
DROP TABLE koper.porto_parishes; --> drop table porto_parishes first
CREATE TABLE koper.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 3 ST_Tile

DROP TABLE koper.porto_parishes; --> drop table porto_parishes first
CREATE TABLE koper.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Konwertowanie rastrów na wektory (wektoryzowanie)
--1 ST_Intersection

create table koper.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--2 ST_DumpAsPolygons


CREATE TABLE koper.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Analiza rastrow
-- 1 ST_Band

CREATE TABLE koper.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- 2 st_clip

CREATE TABLE koper.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--3 ST_Slope
CREATE TABLE koper.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM koper.paranhos_dem AS a;

--4 ST_reclass
CREATE TABLE koper.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM koper.paranhos_slope AS a;

--5 ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM koper.paranhos_dem AS a;

-- 6 - ST_SummaryStats oraz Union
SELECT st_summarystats(ST_Union(a.rast))
FROM koper.paranhos_dem AS a;

--7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM koper.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--8 - ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


--9 ST_Value

SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--10 ST_TPI

create table koper.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON koper.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('koper'::name,
'tpi30'::name,'rast'::name);

-- Zadanie

DROP TABLE IF EXISTS koper.tpi30_porto CASCADE;


CREATE TABLE koper.tpi30_porto AS
WITH porto_geom AS (
    SELECT ST_Union(geom) AS geom
    FROM vectors.porto_parishes
    WHERE municipality ILIKE 'porto'
)
SELECT
    ST_TPI(
        ST_Clip(a.rast, p.geom),
        1
    ) AS rast
FROM rasters.dem AS a
CROSS JOIN porto_geom p
WHERE ST_Intersects(a.rast, p.geom);


CREATE INDEX idx_tpi30_porto_rast_gist ON koper.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('koper'::name,
'tpi30_porto'::name,'rast'::name);

-- ALGEBRA MAP
--1 Wyrażenie Algebry Map

CREATE TABLE koper.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON koper.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('koper'::name,
'porto_ndvi'::name,'rast'::name);

-- 2 Funkcja zwrotna

create or replace function koper.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE koper.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'koper.ndvi(double precision[],
integer[],text[])'::regprocedure, 
'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON koper.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('koper'::name,
'porto_ndvi2'::name,'rast'::name);

-- EKSPORT DANYCH

-- 1 ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM koper.porto_ndvi;

-- 2 ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM koper.porto_ndvi;

SELECT ST_GDALDrivers();

-- 3 Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
 ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
 ) AS loid
FROM koper.porto_ndvi;

SELECT lo_export(loid, 'C:\Users\Public\raster.tiff')
FROM tmp_out;

SELECT lo_unlink(loid)
 FROM tmp_out; 