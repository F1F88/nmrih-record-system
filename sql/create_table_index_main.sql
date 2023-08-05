-- 为了提高插件的插入数据性能，部分表没有添加索引，你可以使用下面语句自行创建
-- 其中被注释掉的语句是在创建表时已经创建的索引
-- 如果你只需要记录，而对于查询需求较少（比如你不需要 Printer 工厂），那么可以考虑不建立索引来提高插入效率

ALTER TABLE map_info
ADD INDEX map_info_1(map_name);

ALTER TABLE round_info
ADD INDEX round_info_1(map_id);
-- ,ADD INDEX round_info_2(obj_chain_md5);

ALTER TABLE round_data
ADD INDEX round_data_1(round_id)
,ADD INDEX round_data_2(steam_id)
,ADD INDEX round_data_3(reason);

ALTER TABLE objective_info
ADD INDEX objective_info_1(round_id);

-- ALTER TABLE player_name
-- ADD UNIQUE KEY player_name_1(steam_id, `name`);

ALTER TABLE watermelon_rescue
ADD INDEX watermelon_rescue_1(round_id)
,ADD INDEX watermelon_rescue_2(steam_id);

-- ALTER TABLE player_stats
-- ADD INDEX player_stats_1(steam_id);