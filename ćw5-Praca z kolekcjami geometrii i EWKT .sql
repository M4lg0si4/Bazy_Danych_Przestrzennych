--1.
DROP TABLE IF EXISTS obiekty;

CREATE TABLE obiekty (
    id SERIAL PRIMARY KEY, 
    nazwa TEXT,
    geom GEOMETRY
);

INSERT INTO obiekty (nazwa, geom)
VALUES 
	('obiekt1',
    'SRID=0;COMPOUNDCURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1),(5 1, 6 1))'),
	('obiekt2',
    'SRID=0;GEOMETRYCOLLECTION(COMPOUNDCURVE((10 6, 10 2), CIRCULARSTRING(10 2, 12 0, 14 2), CIRCULARSTRING(14 2, 16 4, 14 6),(14 6, 10 6)), CIRCULARSTRING(11 2, 13 2, 11 2))'),
	('obiekt3',
    'SRID=0;LINESTRING(7 15, 12 13, 10 17, 7 15)'),
	('obiekt4',
    'SRID=0;LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'),
	('obiekt5',
    'SRID=0;MULTIPOINT Z(30 30 59, 38 32 234)'),
	('obiekt6',
    'SRID=0;GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))');

--2. pole bufora o r=5 wokól lini laczacej o. 3 i 4
SELECT ST_Area(ST_Buffer(ST_ShortestLine(t3.geom, t4.geom), 5)) AS pole_bufora
FROM
    obiekty t3,
    obiekty t4
WHERE
    t3.nazwa = 'obiekt3' AND t4.nazwa = 'obiekt4';

-- 3. zamiana o. 4 na poligon 
UPDATE obiekty
SET geom = ST_MakeLine(geom, ST_StartPoint(geom))
WHERE nazwa = 'obiekt4';

UPDATE obiekty
SET geom = ST_MakePolygon(geom)
WHERE nazwa = 'obiekt4';

SELECT ST_GeometryType(geom)
FROM obiekty 
WHERE nazwa = 'obiekt4';

-- 4. o. 7 jako o. 3 i 4
INSERT INTO obiekty (nazwa, geom)
SELECT
 'obiekt7' AS nazwa,
    ST_Collect(t3.geom, t4.geom) AS geom 
FROM
    obiekty t3,
    obiekty t4
WHERE
    t3.nazwa = 'obiekt3' AND t4.nazwa = 'obiekt4';

-- 5. suma bugorów r=5 dla obiektow bez lukow
SELECT
    SUM(ST_Area(ST_Buffer(geom, 5))) AS suma_buforow_bez_lukow
FROM
    obiekty
WHERE
    ST_HasArc(geom) = FALSE; 