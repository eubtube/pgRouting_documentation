---- ONE to ONE Route ----

SELECT seq, node, edge, a.cost, b.the_geom FROM pgr_dijkstra(
    'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
    121157, 63711, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);

--points are examples only, use your own points from the "Source" field in your "ways" table

---- MANY to ONE Route -----

SELECT seq, node, edge, a.cost, b.the_geom FROM pgr_dijkstra(
    'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
    ARRAY[32, 234, 434, 121157], 51227, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);

--points are examples only, use your own points from the "Source" field in your "ways" table
