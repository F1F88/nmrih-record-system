-- 为了提高插件的插入数据性能，部分表没有添加索引，你可以使用下面语句自行创建
-- 其中被注释掉的语句是在创建表时已经创建的索引
-- 如果你只需要记录，而对于查询需求较少（比如你不需要 Printer 工厂），那么可以考虑不建立索引来提高插入效率

ALTER TABLE player_put_in
ADD INDEX player_put_in_1(round_id)
,ADD INDEX player_put_in_2(steam_id)
,ADD INDEX player_put_in_3 ( `name` );


ALTER TABLE player_hurt
ADD INDEX player_hurt_1(round_id)
,ADD INDEX player_hurt_2(victim_id)
,ADD INDEX player_hurt_3(attacker_id);


ALTER TABLE player_say
ADD INDEX player_say_1(round_id)
,ADD INDEX player_say_2(steam_id);


ALTER TABLE vote_info
ADD INDEX vote_info_1(round_id)
,ADD INDEX vote_info_2(steam_id);


ALTER TABLE player_disconnect
ADD INDEX player_disconnect_1(round_id)
,ADD INDEX player_disconnect_2(steam_id);