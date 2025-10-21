--3
create extension postgis;
--4
CREATE TABLE buildings(
id SERIAL PRIMARY KEY,
geometry GEOMETRY(POLYGON),
name VARCHAR(100)
);

CREATE TABLE roads(
id SERIAL PRIMARY KEY,
geometry GEOMETRY(LINESTRING),
name VARCHAR(100)
);

CREATE TABLE poi(
id SERIAL PRIMARY KEY,
geometry GEOMETRY(POINT),
name VARCHAR(100)
);

--5

INSERT INTO buildings (geometry,name) VALUES
(ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5,  8 4))'),
'BuildingA'),
(ST_GeomFromText('POLYGON((6 5, 6 7, 4 7, 4 5,6 5))'),
'BuildingB'),
(ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'),
'BuildingC'),
(ST_GeomFromText('POLYGON((10 8, 10 9, 9 9, 9 8, 10 8))'),
'BuildingD'),
(ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))'),
'BuildingF');

INSERT INTO roads (geometry,name) VALUES
(ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)'),
'RoadY'),
(ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'),
'RoadX');

INSERT INTO poi (geometry,name) VALUES
(ST_GeomFromText('POINT(1 3.5)'),
'G'),
(ST_GeomFromText('POINT(5.5 1.5)'),
'H'),
(ST_GeomFromText('POINT(9.5 6)'),
'I'),
(ST_GeomFromText('POINT(6.5 6)'),
'J'),
(ST_GeomFromText('POINT(6 9.5)'),
'K');

--6
--a
SELECT SUM(ST_Length(geometry)) AS calkowita_droga
FROM roads;

--b
SELECT ST_AsText(geometry) as geometria, ST_Area(geometry) AS pole_powierzchni, ST_Perimeter(geometry) AS obwod
FROM buildings
WHERE name = 'BuildingA';

--c
SELECT name, ST_Area(geometry) AS pole_powierzchni
FROM buildings
ORDER BY name;

--d
SELECT name, ST_Perimeter(geometry) AS obwod
FROM buildings
ORDER BY ST_Area(geometry) DESC
LIMIT 2;

--e
SELECT ST_Distance(b.geometry, p.geometry) as odleglosc
FROM buildings b
JOIN poi p ON p.name='K'
WHERE b.name='BuildingC';

--f
SELECT ST_Area(ST_Difference(c.geometry, ST_Buffer(b.geometry, 0.5))) as powierzchnia
FROM buildings c
JOIN buildings b ON b.name='BuildingB'
WHERE c.name='BuildingC';

--g
SELECT b.name
FROM buildings b
JOIN roads r ON r.name='RoadX'
WHERE ST_Y(ST_Centroid(b.geometry)) > ST_YMin(r.geometry);

--h
SELECT ST_Area(ST_SymDifference(
c.geometry,
ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')
)) as pole_rozne
FROM buildings c
WHERE c.name='BuildingC';