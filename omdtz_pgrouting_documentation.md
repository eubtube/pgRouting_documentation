
# Step-By-Step Tutorial

![Routing in Dar Es Salaam](https://i.imgur.com/ob7VEey.png)


1. **Prereqs: Install PostgreSQL and PostGIS**

    PostgreSQL and its PostGIS extension are prerequisites for running pgRouting, so make sure these are installed on your system first.  [This post for Linux](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-18-04) and [this video for Windows](https://www.youtube.com/watch?v=tTUM9XfDvqk) are helpful for getting you started.  
    
    Additionally, you’ll want to have the latest version of [QGIS](https://qgis.org/en/site/) downloaded, which is not only great for visualization, but also serves as your `PostgreSQL` administrator, allowing you to run your queries directly from the QGIS database manager (in fact, QGIS started because its creator, Gary Sherman, [wanted a way to easily view his PostGIS data](https://www.xyht.com/spatial-itgis/godfather-of-qgis/) on his home Linux machine, so the QGIS-Postgres connectivity is exceptionally mature).

    Windows users will want to download and install the PostGIS bundle with the StackBuilder application that ships with PostgreSQL (or ensure that the PostGIS bundle for PostgreSQL 11 option is checked when initially downloading PostgreSQL).  This will also install pgRouting, so you can skip step 2.
 
2. **Install pgRouting**
 
    - For Linux users, pgRouting can be installed by following the instructions [here](https://github.com/pgRouting/pgrouting/wiki/Notes-on-Download%2C-Installation-and-building-pgRouting).

    - Mac users using homebrew can find pgRouting using this command:

        ```
        brew install pgrouting
        ```

    - Windows users, install using the PostGIS bundle installation detailed in step 1.
 
3. **Create Extensions for PostGIS and pgRouting**
 
    Use the following query within the Postgres database of your choice to create the necessary extensions to use pgRouting:

    ```sql
    CREATE EXTENSION PostGIS;
    CREATE EXTENSION;
    ```
    
    If you're using pgAdmin4 to do this, you should see this when you click on the extensions for your database:
    
    
  ![daddsad](https://i.imgur.com/jeagOWO.png)
    

    
4. **Download your roads dataset from OSM using the HOT Export Tool**

    Follow the instructions on the HOT Export Tool [site](https://export.hotosm.org/en/v3/) to choose your area of interest and download the data as an OSM `.pbf` file.
    
    Note: if you wanted to consolidate steps 4 and 5, you can also download `.osm` data directly from the site using [Overpass Turbo](https://overpass-turbo.eu/).
 
5. **Convert your `.pbf` file to a `.osm` `XML` file for use with osm2pgrouting using osmconvert**

    OSM `XML` files (using the `.osm` extension) are required for the osm2pgrouting tool and the HOT Export Tool does not support `.osm` downloads. So you'll need to convert your `.pbf` file to `.osm` using osmconvert. 
    
    - To install on Linux:
    
        ```
        sudo apt install osmctools
        ```
    - Windows binaries can be downloaded [here](https://wiki.openstreetmap.org/wiki/Osmconvert#Windows). 
    - The tool doesn't seem to be compatible with Mac, so try using Overpass (see above).

    Enter the following command in the Terminal/Command Prompt to convert:
    
    ```
    osmconvert path/to/file/yourfile.pbf > yourfile.osm
    ```

    
6. **Use osm2pgrouting to Create Your Network Dataset**

    - To install osm2pgrouting on Linux:

        ```
        sudo apt-get install osm2pgsql
        ```
    
   - [Here](http://macappstore.org/osm2pgrouting/) are instructions for Mac download.
    
   - For Windows, this conveniently comes as part of the PostGIS Bundle. If you followed step 1, you should already have osm2pgrouting!
    
    Once you've downloaded, here is the command to create a new network dataset in the Terminal/Control Panel: 
    
    ```
    sudo osm2pgrouting -f your_filename.osm --dbname yourdb_name -U your_user -W your_user_password
    
    # drop the "sudo" in Windows & Mac
    ```
    
    *Note*: You can also manually create a network dataset using only pgRouting and your data.  More on how to do that [here](https://workshop.pgrouting.org/2.5/en/chapters/topology.html#verify-the-routing-network-topology).
 
7. **Set up your Postgres database in QGIS**

    This process will allow you to quickly and easily visualize any queries that you run with Postgres.  As mentioned above, QGIS will also serve as your administrator for Postgres, where you can run your queries and manage your database.  For instructions on how to connect to your Postgres database, check out [this post](http://www.digital-geography.com/postgresql-postgis-brief-introduction/).

    Once your connection is set up, head on over to the DB Manager to access your database.

    [Insert image of DB Manager]

    The DB Manager links directly to your Postgres server and is a surprisingly sussed out admin tool. It is where we ran most of our queries and has some wonderful features including the ability to turn your queries directly into QGIS layers.
    
    To access the SQL query module, click this icon: [insert image of sql icon]

    To save a query as a layer, run the query, then click the "Load as new layer" box at the bottom, fill out the details, then click load to see your layer in the QGIS canvas. This is the best way to visualize your queries going forward. 
    
    [insert image of save as layer]

    With the DB Manager, you are also able to easily save your `SQL` queries within your QGIS project by giving a name to your query and clicking "save" at the top of the query dialogue.
    
8. **Understanding Your Data Tables**
    
    pgRouting creates several data tables for your network dataset, but the most important will be the `ways` table (the lines for your roads, the `ways_vertices_pgr` table (the connecting nodes for all of the lines in your dataset) and the `configuration` table (which gives you information about the type of road in the `ways` table).
    
    Here is a look at each of the tables and what their important attributes mean:
    
    [Insert Image of table 1]
    
    [Insert Image of table 2]
    
    [Insert Image of table 3]

8. **Creating a Weighting Schema**

    The default cost output in your `ways` table will be the same as the distance (in degrees).  If you look carefully at the table, the `distance` (in degrees) column has the same value as the `cost`, indicating that distance is the only thing affecting cost.  We want to change that up to better reflect the cost to travel on our roads.  There are so many ways you can do this, but here is what we did on our project to create a weighting based on type of road:

   1. Look up the `tag_id` values in the `configuration` table automatically generated from pgRouting in your database so that you can find out what the values correspond to.

   2. Create a new column in the `ways` table that groups the roads by type of road that you would like to use.  
    Here's how our query looked: 

    ```sql
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

    --We then deleted anything that was null here (i.e., cycling paths, horse paths) because we did not want to use it in our weighting
    DELETE FROM ways
    WHERE road_rank is null;
    ```

    3. Create a new cost field, weighting how you would like the roads prioritized.  
    Here is our final cost schema:

    ```sql
    UPDATE ways   
    SET cost_4 = (1.1 * length) --nominal cost multiplier mostly for gas and wear & tear.
    WHERE road_rank = 1;

    UPDATE ways
    SET cost_4 = (1.2 * length) --slightly higher for primary
    WHERE road_rank = 2;

    UPDATE ways   
    SET cost_4 = (1.4 * length)   --and for secondary
    WHERE road_rank = 3; 

    UPDATE ways   
    SET cost_4 = (1.6 * length)   --and for tertiary
    WHERE road_rank = 4;

    SET cost_4 = (3.5 * length)  --considerably higher for smaller, slower, generally unpaved roads
    WHERE road_rank = 5;

    UPDATE ways   
    SET cost_4 = (10 * length) 
    --you could choose to remove footpaths altogether, but we kept them and gave them a VERY high cost multiplier
    WHERE road_rank = 6;
    ```   

9. **Test Your Dataset With Some Routing Queries!**

    Your possibilities for routing are limited only by the size of your network dataset!

    pgRouting has several different routing functions, which can be read about [here](http://docs.pgrouting.org/latest/en/routingFunctions.html#routing-functions).  We chose the [pgr_dijkstra](http://docs.pgrouting.org/latest/en/pgr_dijkstra.html#pgr-dijkstra) function, which gives the least-cost path between two nodes in the network dataset.  
  
    You can choose your start and end point for a given route by selecting these nodes in the `ways_vertices_pgr` layer in QGIS then determining the value in the `id` field within the attribute table, which will correspond with the arguments needed in your pgr_djikstra query.

    Or, you can just enter random points and see what route you get!

    Here are a couple different queries to get your routes started:

    **Basic One-to-one Route**
    
    ```sql
    SELECT seq, node, edge, a.cost, b.the_geom FROM pgr_dijkstra(
        'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
        121157, 63711, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);

    --points are examples only, use your own points from the "Source" field in your "ways" table
    ```

    **Many-to-one Route**
    ```sql
    SELECT seq, node, edge, a.cost, b.the_geom FROM pgr_dijkstra(
        'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
        ARRAY[32, 234, 434, 121157], 51227, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);

    --points are examples only, use your own points from the "Source" field in your "ways" table
    ``` 

    *Remember that you can save your queries as QGIS layers using the instructions in section 2*

    You can also add this snippet at the beginning of your query to save the route as a PostGIS table on your Postgres server:

    ```sql
    CREATE TABLE table_name AS SELECT seq,....
    ```



10. **Doing More with Your Routing: Creating Sample Points to Show Fastest Routes from (Roughly) Equally Spaced Points Around a City**
 
    a. Create sample points throughout a bounded area using grid centroids
     - Use the "Create grid" tool to place a grid over your area of interest. If you want it fit to a specific shapefile's area (we used Dar Es Salaam for example), choose "Use Layer Extent..." in the "Extent Field". Choose a distance for your grid (we did 2km by 2km) and ensure that you have a project projection set if units other than degrees are not showing up in the dialogue box.
     - Use the "Centroids tool" to get the centroids of your grid layer.

      b. Snap these sample points to nodes in your network dataset
     - In order to "snap" these points to the road layer, we'll follow a three step process:
         1. Use "Distance Matrix" to get the nearest neighbor from the "ways_vertices_pgr" layer.  Choose your centroids as the input, "ways_vertices_pgr" and "1" in the "Use only the nearest (k) target points". This will return a layer with the input points and the nearest point from the vertices layer.
         2. We need to break these apart, so first we will use the "Multipart to singleparts" tool to break up the distance matrix layer.
         3. Next, run an intersection with the "singleparts" layer and the "ways_vertices_pgr" layer to yield the sample points "snapped" to your road network.

      c. Save the sample points as a new table in your Postgres database
  
     - Use the DB Manager, navigate to your database and click "Import Layer/File" at the top.
     - Call it something like final_sample_points

      d. Run a many-to-one Dijkstra routing function, creating a route from every point in your table of sample points
  
     - Here is the query you'll need to pull in your points from another layer:

        ```sql
        CREATE TABLE table_name AS SELECT seq, path_seq, start_vid, node, edge, a.cost, agg_cost, osm_id, b.the_geom FROM pgr_dijkstra(
            'SELECT gid AS id, source, target, cost_column_name AS cost FROM ways',
            (SELECT ARRAY(SELECT node_field FROM final_sample_points), 51227, FALSE) a LEFT JOIN ways b ON (a.edge = b.gid);
        -- if you follow the steps above, 'node_field' should be 'id_2' 
        -- point values given are examples only, use your own routing points from the "source" field in your "ways" table
        ```

 
    - Did you see how fast that went? Save your routes as a layer and see how it looks in the QGIS canvas.

    e. Visualizing aggregate cost of routes
        
     - Now that you've run your routes, you may want to visualize them! Here is a workflow to do that:
         1. Coercing aggregate cost to your sample points:
             
            If you take a look at the attribute table for your routes, you'll see that each segment for a given route has an aggregate cost associated with it.  These costs build up until they reach the maximum cost. 
            
            In order to coerce the maximum aggregate cost (and therefore the total aggregate cost) from each route into a new table, we can run the following query:
             
            ```sql
            CREATE TABLE cost_join AS SELECT start_vid, agg_cost
              FROM route_all WHERE cost = 0.0;
            ```  
            This query takes every point in the attribute table where 'cost' = 0, which is also the row where 'aggregate_cost' is at its maximum. It throws out the extraneous information, while preserving the 'start_vid' attribute (which corresponds with the starting node of route).
            
            Now, we can join this table to our final_sample_points layer from step 10c above using the following query:

            ```sql
            CREATE TABLE sample_points_cost AS SELECT fid, geom, id_2, osm_id, lon, lat, agg_cost
              FROM final_sample_points LEFT JOIN cost_join
                ON id_2 = start_vid --This line will be specific to your tables, but these fields should match 
            ```
            
            Now you have a new table with cost values appended to your final sample points!  You can nown label all of the starting points with the total aggregate cost to your destination.  
            
            The next step discusses creating a contoured "heatmap" of the cost based on this data.
            
         2. Creating a contoured "heatmap" of your aggregate cost
             
             First, install the QGIS _Contour_ plugin. 
             
             Before you run the tool, _Contour_ only works with single point data and your 'sample_points_cost' layer may be multipart based on the steps above. Go ahead and create a single parts layer using the 'Multipart to singleparts' tool and feed that into the _Contour_ tool.
             
             {insert image}
             
             You'll want to use your `aggregate_cost` as your field to can choose as many or as few contours as you'd like, but we found that 20 was a good number. Your styled output will look something like this:
             
             {insert image}
             
         3. Joining contours with the routes only
         
             We liked the contours, but wanted them to be a little less pronounced, so we sought to show only the route lines with the contour symbology.  While slightly buffering the routes, then clipping the contours to them would have been an obvious solution, this would not have given us dynamic rendering of the data at different scales (as the width of each line would be fixed).
             
             So the solution is to join the routes to the contour layer in QGIS.  Use the dialog box below to do so:
             
             {Insert Image}
             
             Your output should look something like this:
             
             {Insert Image}

    f. Converting aggregate cost into a more meaningful metric
    
    - As it stands, our `aggregate_cost` field doesn't mean much to us. Ideally, we'd like to get this in a format that gives us some useful information.  Travel time is an obvious option.
    - Because we didn't have a tremendous amount of data on speeds of roads and traffic for Dar Es Salaam, we ended up using a major tech company's routing technology combined with our local knowledge of travel times to apply a logarithmic equation to our `aggregate_cost` field.
    - We created a new field `cost_mins` on our 'sample_points_cost' layer from 10e1 above, then applied the logarithmic equation in the field calculator as follows:
        
        {Insert Image}
        
    - This gave us a nice travel time field that we could run also apply to our various visualizations above. 
    
    g. Our final data product:
    
      {insert final map}
    
11. **Extra Resources and Sources Used**
    
    Keep in mind that some of these resources are old, potentially outdated, or use older versions of the tools above. They were very helpful to us in doing this project, but had invalid information several cases.
    
    - https://anitagraser.com/2011/02/07/a-beginners-guide-to-pgrouting/
    - https://workshop.pgrouting.org/2.5/en/index.html
