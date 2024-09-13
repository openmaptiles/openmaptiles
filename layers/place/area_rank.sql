CREATE OR REPLACE FUNCTION area_rank(area real) RETURNS int AS
$$
SELECT CASE
           WHEN area > 640000000 THEN 1
           WHEN area > 160000000 THEN 2
           WHEN area > 40000000 THEN 3
           WHEN area > 15000000 THEN 4
           WHEN area > 10000000 THEN 5
           WHEN area > 0 THEN 6
           ELSE 7
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;
