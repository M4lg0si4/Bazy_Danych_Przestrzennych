--1
SELECT b19.*
FROM "T2019_KAR_BUILDINGS" b19
LEFT JOIN "T2018_KAR_BUILDINGS" b18 ON ST_Equals(b19.geom, b18.geom)
WHERE b18.geom IS NULL;


--2
WITH new_b AS (
    SELECT b19.*
    FROM "T2019_KAR_BUILDINGS" b19
    LEFT JOIN "T2018_KAR_BUILDINGS" b18
      ON ST_Equals(b19.geom, b18.geom)
    WHERE b18.geom IS NULL
),
new_p AS (
    SELECT p19.*
    FROM "T2019_KAR_POI_TABLE" p19
    LEFT JOIN "T2018_KAR_POI_TABLE" p18
      ON ST_Equals(p19.geom, p18.geom)
    WHERE p18.geom IS NULL
)
SELECT np.type, COUNT(*) AS p_count
FROM new_p np
JOIN new_b nb
  ON ST_DWithin(np.geom, nb.geom, 500)
GROUP BY np.type
ORDER BY p_count DESC;

--3
CREATE TABLE streets_reprojected AS
SELECT 
    *, 
    ST_Transform(geom, 31468) AS geom 
FROM "T2019_KAR_STREETS";

--4
INSERT INTO input_points (geom)
VALUES
    (ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
    (ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));

--5
ALTER TABLE input_points
ALTER COLUMN geom TYPE geometry(Point, 31468)
USING ST_SetSRID(geom, 31468);


--6
WITH line_from_points AS (
    SELECT 
        ST_MakeLine(geom ORDER BY id) AS geom
    FROM input_points
)
SELECT sn.*
FROM "T2019_STREET_NODE" sn,
     line_from_points l
WHERE ST_DWithin(
    ST_Transform(sn.geom, 31468),
    l.geom, 
    200
);

--7
SELECT COUNT(DISTINCT p.id) AS sport_shops_near_parks
FROM "T2019_KAR_POI_TABLE" p
JOIN "T2019_KAR_LAND_USE_A" park
  ON ST_DWithin(
      ST_Transform(p.geom, 31468),
      ST_Transform(park.geom, 31468),
      300
     )
WHERE p.type = 'Sporting Goods Store';

--8

CREATE TABLE "T2019_KAR_BRIDGES" AS
SELECT 
    ST_Intersection(
        ST_Transform(r.geom, 31468),
        ST_Transform(w.geom, 31468)
    ) AS geom
FROM "T2019_KAR_RAILWAYS" r
JOIN "T2019_KAR_WATER_LINES" w
  ON ST_Intersects(
        ST_Transform(r.geom, 31468),
        ST_Transform(w.geom, 31468)
     )
WHERE NOT ST_IsEmpty(
        ST_Intersection(
            ST_Transform(r.geom, 31468),
            ST_Transform(w.geom, 31468)
        )
      );
