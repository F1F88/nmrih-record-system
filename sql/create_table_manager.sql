
-- * manager
-- ----------------------------------------------------------------------------------------------------------------
-- player_put_in
-- 新增条件: 玩家进入服务器. 用于发生纠纷时获取信息
-- DROP TABLE IF EXISTS player_put_in;
CREATE TABLE IF NOT EXISTS player_put_in (
    `id`                        INT UNSIGNED        NOT NULL    AUTO_INCREMENT,

    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',
    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `name`                      VARCHAR ( 128 )     NOT NULL    COMMENT '玩家昵称',

    `ip`                        VARCHAR ( 32 )                  COMMENT '',
    `country`                   VARCHAR ( 32 )                  COMMENT '',
    `continent`                 VARCHAR ( 32 )                  COMMENT '',
    `region`                    VARCHAR ( 32 )                  COMMENT '',
    `city`                      VARCHAR ( 32 )                  COMMENT '',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX player_put_in_1 ( round_id )
--     , INDEX player_put_in_2 ( steam_id )
--     , INDEX player_put_in_3 ( `name` )
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
    `id`                        INT UNSIGNED        NOT NULL    AUTO_INCREMENT,
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
-- player_say
-- 新增条件: 玩家发言
-- DROP TABLE IF EXISTS player_say;
CREATE TABLE IF NOT EXISTS player_say (
    `id`                        INT UNSIGNED        NOT NULL    AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `text`                      VARCHAR ( 256 )                 COMMENT '',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX player_say_1 ( round_id )
--     , INDEX player_say_2 ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- vote_submit
-- 新增条件: 调用命令 callvote 且参数 > 1
-- DROP TABLE IF EXISTS vote_submit;
CREATE TABLE IF NOT EXISTS vote_submit (
    `id`                        INT UNSIGNED        NOT NULL    AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `vote_info`                 VARCHAR ( 32 )                  COMMENT '发起的投票信息',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    -- , INDEX vote_submit_round_id ( round_id )
    -- , INDEX vote_submit_steam_id ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
-- vote_option
-- 新增条件: 玩家选择投票
-- DROP TABLE IF EXISTS vote_option;
CREATE TABLE IF NOT EXISTS vote_option (
    `id`                        INT UNSIGNED        NOT NULL    AUTO_INCREMENT,
    `vote_id`                   INT UNSIGNED        NOT NULL    COMMENT '投票id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `vote_option`               TINYINT                         COMMENT '玩家做出的选项',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
    -- , INDEX vote_option_vote_id (vote_id)
    -- , INDEX vote_option_steam_id ( steam_id )
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
    `id`                        INT UNSIGNED        NOT NULL    AUTO_INCREMENT,
    `round_id`                  INT UNSIGNED        NOT NULL    COMMENT '回合id',

    `steam_id`                  INT                 NOT NULL    COMMENT '玩家 STEAM ID',
    `reason`                    VARCHAR ( 128 )                 COMMENT '离开原因',
    `networkid`                 VARCHAR ( 32 )                  COMMENT '',
    `play_time`                 MEDIUMINT UNSIGNED  DEFAULT 0   COMMENT '游玩时长',

    `create_time`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY ( id )
--     , INDEX player_disconnect_1 ( round_id )
--     , INDEX player_disconnect_2 ( steam_id )
)
DEFAULT CHARSET = utf8mb4
ENGINE = INNODB ;
-- ----------------------------------------------------------------------------------------------------------------








