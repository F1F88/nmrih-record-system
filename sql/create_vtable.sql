-- v_objective_info
DROP VIEW IF EXISTS v_objective_data;
CREATE VIEW v_objective_data AS
-- SELECT *
-- FROM
-- (
    (
        SELECT  map_info.id                                             AS map_id
               ,map_info.map_name                                       AS map_name
               ,map_info.start_time                                     AS map_start_time
               ,map_info.end_time                                       AS map_end_time

               ,round_info.id                                           AS round_id
               ,IF(round_info.practice=1, "True", "False")              AS round_practice
               ,round_info.start_time                                   AS round_start_time
               ,round_info.end_time                                     AS round_end_time
               ,round_info.round_begin_time                             AS round_begin_time
               ,round_info.extraction_begin_time                        AS round_extraction_begin_time
               ,round_info.round_len                                    AS round_len
               ,round_info.obj_chain_md5                                AS round_obj_chain_md5

               ,obj_info.id                                             AS obj_id
               ,obj_info.engine_time                                    AS obj_engine_time
               ,obj_info.serial                                         AS obj_serial
               ,IF(obj_info.id=-1, "NMS", CAST(obj_info.id AS CHAR))    AS obj_id2
               ,obj_info.obj_info                                       AS obj_info
               ,CASE obj_info.resupply
                      WHEN  -1 THEN 'NMO'
                      WHEN   0 THEN 'False'
                      WHEN   1 THEN 'True'
               END AS obj_resupply
               ,obj_info.create_time                                AS obj_create_time
        FROM map_info
        LEFT JOIN round_info ON map_info.id = round_info.map_id
        LEFT JOIN objective_info AS obj_info ON round_info.id = obj_info.round_id
        ORDER BY map_id, round_id, obj_id
    )
--     UNION
--     (
--         SELECT  map_info.id                                             AS map_id
--                ,map_info.map_name                                       AS map_name
--                ,map_info.start_time                                     AS map_start_time
--                ,map_info.end_time                                       AS map_end_time

--                ,round_info.id                                           AS round_id
--                ,IF(round_info.practice=1, "True", "False")              AS round_practice
--                ,round_info.start_time                                   AS round_start_time
--                ,round_info.end_time                                     AS round_end_time
--                ,round_info.round_begin_time                             AS round_begin_time
--                ,round_info.extraction_begin_time                        AS round_extraction_begin_time
--                ,round_info.round_len                                    AS round_len
--                ,round_info.obj_chain_md5                                AS round_obj_chain_md5

--                ,obj_info.id                                             AS obj_id
--                ,obj_info.engine_time                                    AS obj_engine_time
--                ,obj_info.serial                                         AS obj_serial
--                ,IF(obj_info.id=-1, "NMS", CAST(obj_info.id AS CHAR))    AS obj_id2
--                ,obj_info.obj_info                                       AS obj_info
--                ,CASE obj_info.resupply
--                       WHEN  -1 THEN 'NMO'
--                       WHEN   0 THEN 'False'
--                       WHEN   1 THEN 'True'
--                END AS obj_resupply
--                ,obj_info.create_time                                AS obj_create_time
--         FROM map_info
--         LEFT JOIN round_info ON map_info.id = round_info.map_id
--         LEFT JOIN objective_info AS obj_info ON round_info.id = obj_info.round_id
--     )
-- ) AS t
-- ORDER BY map_id, round_id, obj_id;


-- v_round_player_data
DROP VIEW IF EXISTS v_round_player_data;
CREATE VIEW v_round_player_data AS
SELECT  map_info.map_name AS map_name
        ,map_info.map_name                                       AS map_name
        ,map_info.start_time                                     AS map_start_time
        ,map_info.end_time                                       AS map_end_time

        ,round_info.id                                           AS round_id
        ,IF(round_info.practice=1, "True", "False")              AS round_practice
        ,round_info.start_time                                   AS round_start_time
        ,round_info.end_time                                     AS round_end_time
        ,round_info.round_begin_time                             AS round_begin_time
        ,round_info.extraction_begin_time                        AS round_extraction_begin_time
        ,round_info.round_len                                    AS round_len
        ,round_info.obj_chain_md5                                AS round_obj_chain_md5


FROM map_info
LEFT JOIN round_info ON map_info.id = round_info.map_id
LEFT JOIN objective_info AS obj_info ON round_info.id = obj_info.round_id
WHERE id IN(SELECT  MAX(id) AS max_id FROM player_name GROUP BY steam_id)
ORDER BY id;



-- v_player_name
DROP VIEW IF EXISTS v_player_name;
CREATE VIEW v_player_name AS
SELECT  *
FROM player_name
WHERE id IN(SELECT  MAX(id) AS max_id FROM player_name GROUP BY steam_id)
ORDER BY id;






-- manager
SELECT player_hurt.*
FROM player_hurt