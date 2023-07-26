-- ALTER TABLE map_info
-- ADD INDEX map_info_1(map_name);

-- ALTER TABLE round_info
-- ADD INDEX round_info_1(map_id)
-- ,ADD INDEX round_info_2(obj_chain_md5);

-- ALTER TABLE round_data
-- ADD INDEX round_data_1(round_id)
-- -- ,ADD INDEX round_data_2(steam_id)
-- ,ADD INDEX round_data_3(reason);

ALTER TABLE objective_info
ADD INDEX objective_info_1(round_id);

ALTER TABLE player_name
ADD INDEX player_name_1(steam_id, `name`);

ALTER TABLE player_hurt
ADD INDEX player_hurt_1(round_id)
,ADD INDEX player_hurt_2(victim_id)
,ADD INDEX player_hurt_3(attacker_id);

ALTER TABLE watermelon_rescue
ADD INDEX watermelon_rescue_1(round_id)
,ADD INDEX watermelon_rescue_2(steam_id);

-- ALTER TABLE player_stats
-- ADD INDEX player_stats_1(steam_id);