-- This might be easier to digest!: https://hackmd.io/XWzhXk-kRL6IWzjZcVHIBA

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
 
---- Route for Multiple Points to a Single Point (As an array from a table of points) ----    
    
-- The columns selected in the SELECT statement will vary based on what you want to have in your output table and which ones you create in your table of nodes

SELECT seq, path_seq, start_vid, node, edge, a.cost, agg_cost, osm_id, b.the_geom FROM pgr_dijkstra(
    'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
    (SELECT ARRAY(SELECT node_field FROM table_of_node_ids)), 51227, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);

--points are examples only, use your own points from the "Source" field in your "ways" table

---- As a Table! ----     
CREATE TABLE route_all AS SELECT seq, path_seq, start_vid, node, edge, a.cost, agg_cost, osm_id, b.the_geom FROM pgr_dijkstra(
    'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
    (SELECT ARRAY(SELECT node_field FROM table_of_node_ids)), 51227, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);
     
---- Create OSM Road Categories (Example) ----
ALTER TABLE ways 
ADD road_rank bigint;

UPDATE ways   
SET road_rank = 1  
WHERE tag_id = 104 or tag_id = 105; --trunk roads

UPDATE ways   
SET road_rank = 2 
WHERE tag_id = 106 or tag_id = 107; --primary roads

UPDATE ways   
SET road_rank = 3 
WHERE tag_id = 108 or tag_id = 124; --secondary roads

UPDATE ways   
SET road_rank = 4
WHERE tag_id = 109 or tag_id = 125; --tertiary roads

UPDATE ways   
SET road_rank = 5
WHERE tag_id = 110 or tag_id = 112 or tag_id = 113 or tag_id = 123; 
--unclassified, track, residential and service roads

UPDATE ways   
SET road_rank = 6
WHERE tag_id = 117 or tag_id = 114 or tag_id = 119; --footpaths, paths, or footways

--We then deleted anything that was null here because we did not want to use it in our weighting
DELETE FROM ways
WHERE road_rank is null;

---- Update Cost Column with Weighting for Type of Road ----
     
UPDATE ways   
SET cost_4 = (1.1 * length)   
WHERE road_rank = 1;

UPDATE ways
SET cost_4 = (1.2 * length) 
WHERE road_rank = 2;

UPDATE ways   
SET cost_4 = (1.4 * length)   
WHERE road_rank = 3; 

UPDATE ways   
SET cost_4 = (1.6 * length)   
WHERE road_rank = 4;
 
SET cost_4 = (3.5 * length) 
WHERE road_rank = 5;
 
UPDATE ways   
SET cost_4 = (10 * length) 
WHERE road_rank = 6;
     
---- Joining Aggregate Cost to Sample Points (for Visualization) ----
     
-- 1: Create Table For Joining Aggregate Cost (From a Route Table) to Route Points     
 
CREATE TABLE cost_join AS SELECT start_vid, agg_cost
  FROM route_all WHERE cost = 0.0;
     
-- 2: Join Aggregate Cost Table to Route Points in New Table

CREATE TABLE sample_points_cost AS SELECT fid, geom, id_2, osm_id, lon, lat, agg_cost
  FROM final_sample_points LEFT JOIN cost_join
    ON id_2 = start_vid --This line will be specific to your tables, but these fields should match

---- Adding a Cost Column ----
 
ALTER TABLE nodes_table_to_modify
ADD cost_minutes bigint;

UPDATE nodes_table_to_modify
SET cost_minutes = log(agg_cost + 1.01)*600; 
-- Here is the logarithmic equation we used, just an example 
-- Yours will likely be different 
     
---- Snap a Point to Its Closest Point on the Road Network ----
 
CREATE TABLE snapped_table AS SELECT a.id, ST_Closestpoint(ST_Collect(b.geom), a.geom) AS geom
FROM snap_from_table a, snap_to_table b
GROUP BY a.id, a.geom; --or whatever you would like to group by
