CREATE TABLE wynik AS
SELECT ST_Union(geom::geometry)::geography AS geom
FROM "Exports";
