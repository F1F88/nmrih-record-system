-- * nmrih_record

-- ----------------------------------------------------------------------------------------------------------------
-- map_info
-- 在 OnMapStart 时添加
-- 在 OnMapEnd 时更新结束时间
-- DROP TABLE IF EXISTS map_info;
CREATE TABLE IF NOT EXISTS map_info (
    `id`                        INT UNSIGNED AUTO_INCREMENT,

    `map_name`                  VARCHAR ( 64 )      NOT NULL    COMMENT '地图名称',
    `start_time`                DOUBLE              DEFAULT 0   COMMENT 'OnMapStart 时间',
    `end_time`                  DOUBLE              DEFAULT 0   COMMENT 'OnMapEnd 时间',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY ( id )
    , INDEX map_info_1 ( map_name )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- round_info
-- 只在两种情况下新增、更新 end_time:
-- nmrih_practice_ending
--     字段 practice == 1   |   obj_len = 0     |   obj_chain_md5 = NULL_STRING
--     只有 start_time 和 end_time
-- nmrih_reset_map
--     字段 practice == 0
--     如果玩家在 nmrih_round_begin 前退出, 则没有 round_begin_time
-- nmrih_round_begin: 只更新 round_begin_time,      用于计时 -> 回合开始时间
-- extraction_begin:  只更新 extraction_begin_time, 用于计时 -> 撤离开始时间
-- DROP TABLE IF EXISTS round_info;
CREATE TABLE IF NOT EXISTS round_info (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `map_id`                    INT UNSIGNED        NOT NULL    COMMENT '地图id',

    `practice`                  TINYINT             NOT NULL    COMMENT '是否为练习回合',
    `start_time`                DOUBLE              NOT NULL    COMMENT 'Round 开始时间',
    `end_time`                  DOUBLE              DEFAULT 0   COMMENT 'Round 结束时间',
    `round_begin_time`          DOUBLE              DEFAULT 0   COMMENT 'nmrih_round_begin 时间',
    `extraction_begin_time`     DOUBLE              DEFAULT 0   COMMENT 'extraction_begin 时间',

    `round_len`                 SMALLINT            DEFAULT 0   COMMENT '任务链长度(任务个数) / wave_end(找不到 overlord_wave_controller 时为-1)',
    `obj_chain_md5`             VARCHAR ( 64 )      NOT NULL    COMMENT '任务链 MD5 Hash 值/地图名字 (NMO使用任务链计算, NMS为地图名字, 练习时间为practice)',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY ( id )
    , INDEX round_info_1 ( map_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------------------------------------
-- round_data
-- 只有新增, 没有更新
-- 新增条件: nmrih_reset_map(game_reastrt)、player_extracted、player_death、player_leave
-- DROP TABLE IF EXISTS round_data;
CREATE TABLE IF NOT EXISTS round_data (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `reason`                    VARCHAR ( 32 )      NOT NULL    COMMENT '数据结算理由 (事件)',
    `engine_time`               DOUBLE              NOT NULL    COMMENT '结算时间 (EngineTime)',
    `spawn_time`                DOUBLE              NOT NULL    COMMENT '复活时间',

    `taken_cnt_pills`           TINYINT UNSIGNED    DEFAULT 0   COMMENT '',
    `taken_cnt_gene_therapy`    TINYINT UNSIGNED    DEFAULT 0   COMMENT '',
    `effect_cnt_gene_therapy`   TINYINT UNSIGNED    DEFAULT 0   COMMENT '',

    `share_cnt_bandages`        SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `share_cnt_first_aid`       SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `share_cnt_pills`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `share_cnt_gene_therapy`    SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `receive_cnt_bandages`      SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `receive_cnt_first_aid`     SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `receive_cnt_pills`         SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `receive_cnt_gene_therapy`  SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',

    `kill_cnt_total`            SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_head`             SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_shambler`         SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_runner`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_kid`              SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_turned`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_player`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_melee`            SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_firearm`          SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_explode`          SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `kill_cnt_flame`            SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',

    `inflict_cnt_player`        SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',

    `inflict_dmg_total`         INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_shambler`      INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_runner`        INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_kid`           INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_turned`        INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_player`        INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_melee`         INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_firearm`       INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_explode`       INT UNSIGNED        DEFAULT 0   COMMENT '',
    `inflict_dmg_flame`         INT UNSIGNED        DEFAULT 0   COMMENT '',

    `hurt_cnt_total`            SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `hurt_cnt_bleed`            SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `hurt_cnt_shambler`         SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `hurt_cnt_runner`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `hurt_cnt_kid`              SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `hurt_cnt_turned`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',
    `hurt_cnt_player`           SMALLINT UNSIGNED   DEFAULT 0   COMMENT '',

    `hurt_dmg_total`            INT UNSIGNED        DEFAULT 0   COMMENT '',
    `hurt_dmg_bleed`            INT UNSIGNED        DEFAULT 0   COMMENT '',
    `hurt_dmg_shambler`         INT UNSIGNED        DEFAULT 0   COMMENT '',
    `hurt_dmg_runner`           INT UNSIGNED        DEFAULT 0   COMMENT '',
    `hurt_dmg_kid`              INT UNSIGNED        DEFAULT 0   COMMENT '',
    `hurt_dmg_turned`           INT UNSIGNED        DEFAULT 0   COMMENT '',
    `hurt_dmg_player`           INT UNSIGNED        DEFAULT 0   COMMENT '',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    , INDEX round_data_1 ( round_id )
    -- , INDEX round_data_2 ( steam_id )
    , INDEX round_data_3(reason)
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- objective_info
-- 只有新增, 没有更新
-- 新增条件:
--     触发新的 任务/wave
--     触发撤离开始
-- DROP TABLE IF EXISTS objective_info;
CREATE TABLE IF NOT EXISTS objective_info (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `engine_time`               DOUBLE              NOT NULL    COMMENT '任务/wave 开始的时间 (EngineTime)',
    `serial`                    SMALLINT            NOT NULL    COMMENT '本回合的第几个 任务/wave',

    `obj_id`                    INT                 NOT NULL    COMMENT '任务ID (NMS地图为-1)',
    `obj_info`                  VARCHAR ( 256 )                 COMMENT '任务信息 (NMS地图为 NULL_STRING)',

    `resupply`                  TINYINT             NOT NULL    COMMENT 'wave的resupply(NMO为-1)',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    -- , INDEX objective_info_1 ( round_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------



-- ----------------------------------------------------------------------------------------------------------------
-- player_name
-- 只有新增, 没有更新
-- 新增条件: 玩家成功授权, 且数据库中没有这名玩家的 steam_id + 名字
-- DROP TABLE IF EXISTS player_name;
CREATE TABLE IF NOT EXISTS player_name (
    `id`                        INT UNSIGNED AUTO_INCREMENT,

    `steam_id`                  INT                 NOT NULL     COMMENT '玩家 STEAM ID',
    `name`                      VARCHAR ( 128 )     NOT NULL     COMMENT '玩家名称',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    -- , INDEX player_name_1 ( steam_id, `name` )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------------------------------------
-- player_hurt
-- 只有新增, 没有更新
-- 新增条件: 玩家被攻击
-- DROP TABLE IF EXISTS player_hurt;
CREATE TABLE IF NOT EXISTS player_hurt (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `engine_time`               DOUBLE              NOT NULL    COMMENT 'EngineTime',

    `victim_id`                 INT                 NOT NULL    COMMENT '受害者的 STEAM ID',
    `attacker_id`               INT                 NOT NULL    COMMENT '攻击者的 ID | 玩家时为 STEAM ID, 其他为实体 index (不超过2049)',
    `weapon_name`               VARCHAR ( 32 )                 COMMENT '武器名称 (常规: player、***zombie | 特殊值: _bleed, _infected, _self)',
    `damage`                    SMALLINT UNSIGNED   DEFAULT 0   COMMENT '实际造成的伤害',
    `damage_type`               INT                 DEFAULT 0   COMMENT '造成的伤害类型',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    -- , INDEX player_hurt_1 ( round_id )
    -- , INDEX player_hurt_2 ( victim_id )
    -- , INDEX player_hurt_3 ( attacker_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------------------------------------
-- watermelon_rescue
-- 只有新增, 没有更新
-- 新增条件: watermelon_rescue
-- DROP TABLE IF EXISTS watermelon_rescue;
CREATE TABLE IF NOT EXISTS watermelon_rescue (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `engine_time`               DOUBLE              NOT NULL    COMMENT 'EngineTime',
    `steam_id`                  INT                 NOT NULL    COMMENT '受害者的 STEAM ID',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    -- , INDEX watermelon_rescue_1 ( round_id )
    -- , INDEX watermelon_rescue_2 ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------------------------------------
-- player_stats
-- 更新条件: 撤离、离开游戏、回合重启
-- 新增条件: 玩家进入服务器, 且为查询到steam_id
-- DROP TABLE IF EXISTS player_stats;
CREATE TABLE IF NOT EXISTS player_stats (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',

    `play_time`                 INT UNSIGNED        DEFAULT 0   COMMENT '',
    `extracted_cnt_total`       INT UNSIGNED        DEFAULT 0   COMMENT '',

    `kill_cnt_total`            INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_head`             INT UNSIGNED        DEFAULT 0   COMMENT '',

    `kill_cnt_shambler`         INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_runner`           INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_kid`              INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_turned`           INT UNSIGNED        DEFAULT 0   COMMENT '',

    `kill_cnt_player`           INT UNSIGNED        DEFAULT 0   COMMENT '',

    `kill_cnt_melee`            INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_firearm`          INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_explode`          INT UNSIGNED        DEFAULT 0   COMMENT '',
    `kill_cnt_flame`            INT UNSIGNED        DEFAULT 0   COMMENT '',

    `taken_cnt_pills`           INT UNSIGNED        DEFAULT 0   COMMENT '',
    `taken_cnt_gene_therapy`    INT UNSIGNED        DEFAULT 0   COMMENT '',
    `effect_cnt_gene_therapy`   INT UNSIGNED        DEFAULT 0   COMMENT '',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY ( id )
    , INDEX player_stats_1 ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------



-- * manager
-- ----------------------------------------------------------------------------------------------------------------
-- player_put_in
-- 新增条件: 玩家进入服务器. 用于发生纠纷时获取信息
-- DROP TABLE IF EXISTS player_put_in;
CREATE TABLE IF NOT EXISTS player_put_in (
    `id`                        INT UNSIGNED AUTO_INCREMENT,

    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',
    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',

    `ip`                        VARCHAR ( 32 )                  COMMENT '',
    `country`                   VARCHAR ( 32 )                  COMMENT '',
    `continent`                 VARCHAR ( 32 )                  COMMENT '',
    `region`                    VARCHAR ( 32 )                  COMMENT '',
    `city`                      VARCHAR ( 32 )                  COMMENT '',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX player_put_in_1 ( map_id, round_id )
--     , INDEX player_put_in_2 ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- player_say
-- 新增条件: 玩家发言
-- DROP TABLE IF EXISTS player_say;
CREATE TABLE IF NOT EXISTS player_say (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `text`                      VARCHAR ( 256 )                 COMMENT '',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX player_say ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- vote_info
-- 新增条件:
--     调用命令 callvote 且参数 > 1
--     玩家触发投票选择
-- DROP TABLE IF EXISTS vote_info;
CREATE TABLE IF NOT EXISTS vote_info (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `vote_info`                 VARCHAR ( 32 )                  COMMENT '发起的投票信息',
    `vote_option`               TINYINT                         COMMENT '玩家做出的选项',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX vote_info ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- player_disconnect
-- 新增条件:
--     玩家离开服务器
-- DROP TABLE IF EXISTS player_disconnect;
CREATE TABLE IF NOT EXISTS player_disconnect (
    `id`                        INT UNSIGNED AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `reason`                    VARCHAR ( 128 )                 COMMENT '离开原因',
    `networkid`                 VARCHAR ( 32 )                  COMMENT 'ip地址',
    `play_time`                 SMALLINT UNSIGNED   DEFAULT 0   COMMENT '游玩时长',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX vote_info ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------








