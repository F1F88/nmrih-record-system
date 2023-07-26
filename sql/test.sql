

SELECT (round_data.engine_time - round_info.round_begin_time) AS take_time
    ,map_info.id AS map_id, map_info.map_name AS map_name, round_info.id AS round_id
FROM map_info
INNER JOIN round_info ON map_info.id = round_info.map_id
INNER JOIN round_player_data AS round_data ON round_info.id = round_data.round_id
WHERE map_info.map_name = '%s' AND round_info.obj_chain_md5 = '%s' AND round_data.reason = 'extracted'
