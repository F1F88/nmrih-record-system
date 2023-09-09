#pragma newdecls required
#pragma semicolon 1

#undef  	    MAXPLAYERS
#define         MAXPLAYERS                                  9

#define         MAX_WEAPON_LEN                              32


int             private_player_offset_bleedingOut
                , private_player_offset_InfectionTime
                , private_player_offset_InfectionDeathTime;


float           cv_player_ff_factor
                , cv_player_bleedout_dmg
                , cv_player_connected_delay_time
                , cv_player_play_time_interval;

float           private_player_spawn_time[MAXPLAYERS + 1]
                , private_player_play_time[MAXPLAYERS + 1];

bool            private_player_aready_submit_data[MAXPLAYERS + 1];

int             private_player_prefs[MAXPLAYERS + 1]
                , private_player_steam_id[MAXPLAYERS + 1]
                , private_player_put_in_time[MAXPLAYERS + 1]

                , private_player_taken_cnt_pills[MAXPLAYERS + 1]
                , private_player_taken_cnt_gene_therapy[MAXPLAYERS + 1]
                , private_player_effect_cnt_gene_therapy[MAXPLAYERS + 1]

                , private_player_share_cnt_bandages[MAXPLAYERS + 1]
                , private_player_share_cnt_first_aid[MAXPLAYERS + 1]
                , private_player_share_cnt_pills[MAXPLAYERS + 1]
                , private_player_share_cnt_gene_therapy[MAXPLAYERS + 1]
                , private_player_receive_cnt_bandages[MAXPLAYERS + 1]
                , private_player_receive_cnt_first_aid[MAXPLAYERS + 1]
                , private_player_receive_cnt_pills[MAXPLAYERS + 1]
                , private_player_receive_cnt_gene_therapy[MAXPLAYERS + 1]

                , private_player_kill_cnt_total[MAXPLAYERS + 1]
                , private_player_kill_cnt_headSplit[MAXPLAYERS + 1]
                , private_player_kill_cnt_shambler[MAXPLAYERS + 1]
                , private_player_kill_cnt_runner[MAXPLAYERS + 1]
                , private_player_kill_cnt_kid[MAXPLAYERS + 1]
                , private_player_kill_cnt_turned[MAXPLAYERS + 1]
                , private_player_kill_cnt_player[MAXPLAYERS + 1]
                , private_player_kill_cnt_melee[MAXPLAYERS + 1]
                , private_player_kill_cnt_firearm[MAXPLAYERS + 1]
                , private_player_kill_cnt_explode[MAXPLAYERS + 1]
                , private_player_kill_cnt_flame[MAXPLAYERS + 1]

                , private_player_inflict_cnt_player[MAXPLAYERS + 1]     // to manager

                , private_player_inflict_dmg_total[MAXPLAYERS + 1]
                , private_player_inflict_dmg_shambler[MAXPLAYERS + 1]
                , private_player_inflict_dmg_runner[MAXPLAYERS + 1]
                , private_player_inflict_dmg_kid[MAXPLAYERS + 1]
                , private_player_inflict_dmg_turned[MAXPLAYERS + 1]
                , private_player_inflict_dmg_player[MAXPLAYERS + 1]
                , private_player_inflict_dmg_melee[MAXPLAYERS + 1]
                , private_player_inflict_dmg_firearm[MAXPLAYERS + 1]
                , private_player_inflict_dmg_explode[MAXPLAYERS + 1]
                , private_player_inflict_dmg_flame[MAXPLAYERS + 1]

                , private_player_hurt_cnt_total[MAXPLAYERS + 1]
                , private_player_hurt_cnt_bleed[MAXPLAYERS + 1]
                , private_player_hurt_cnt_shambler[MAXPLAYERS + 1]
                , private_player_hurt_cnt_runner[MAXPLAYERS + 1]
                , private_player_hurt_cnt_kid[MAXPLAYERS + 1]
                , private_player_hurt_cnt_turned[MAXPLAYERS + 1]
                , private_player_hurt_cnt_player[MAXPLAYERS + 1]

                , private_player_hurt_dmg_total[MAXPLAYERS + 1]
                , private_player_hurt_dmg_bleed[MAXPLAYERS + 1]
                , private_player_hurt_dmg_shambler[MAXPLAYERS + 1]
                , private_player_hurt_dmg_runner[MAXPLAYERS + 1]
                , private_player_hurt_dmg_kid[MAXPLAYERS + 1]
                , private_player_hurt_dmg_turned[MAXPLAYERS + 1]
                , private_player_hurt_dmg_player[MAXPLAYERS + 1];

methodmap NRPlayerData __nullable__
{
    public NRPlayerData(int client) {
        return view_as<NRPlayerData>(client);
    }

    property int index {
        public get()                    { return view_as<int>(this); }
    }

    property int prefs {
        public get()                    { return private_player_prefs[this.index]; }
        public set(int value)           { private_player_prefs[this.index] = value; }
    }

    property int steam_id {
        public get()                    { return private_player_steam_id[this.index]; }
        public set(int value)           { private_player_steam_id[this.index] = value; }
    }

    property int put_in_time {
        public get()                    { return private_player_put_in_time[this.index]; }
        public set(int value)           { private_player_put_in_time[this.index] = value; }
    }

    property float spawn_time {
        public get()                    { return private_player_spawn_time[this.index]; }
        public set(float value)         { private_player_spawn_time[this.index] = value; }
    }

    property float play_time {
        public get()                    { return private_player_play_time[this.index]; }
        public set(float value)         { private_player_play_time[this.index] = value; }
    }

    property bool aready_submit_data {
        public get()                    { return private_player_aready_submit_data[this.index]; }
        public set(bool value)          { private_player_aready_submit_data[this.index] = value; }
    }


    property int taken_cnt_pills {
        public get()                    { return private_player_taken_cnt_pills[this.index]; }
        public set(int value)           { private_player_taken_cnt_pills[this.index] = value; }
    }

    property int taken_cnt_gene_therapy {
        public get()                    { return private_player_taken_cnt_gene_therapy[this.index]; }
        public set(int value)           { private_player_taken_cnt_gene_therapy[this.index] = value; }
    }

    property int effect_cnt_gene_therapy {
        public get()                    { return private_player_effect_cnt_gene_therapy[this.index]; }
        public set(int value)           { private_player_effect_cnt_gene_therapy[this.index] = value; }
    }


    property int share_cnt_bandages {
        public get()                    { return private_player_share_cnt_bandages[this.index]; }
        public set(int value)           { private_player_share_cnt_bandages[this.index] = value; }
    }

    property int share_cnt_first_aid {
        public get()                    { return private_player_share_cnt_first_aid[this.index]; }
        public set(int value)           { private_player_share_cnt_first_aid[this.index] = value; }
    }

    property int share_cnt_pills {
        public get()                    { return private_player_share_cnt_pills[this.index]; }
        public set(int value)           { private_player_share_cnt_pills[this.index] = value; }
    }

    property int share_cnt_gene_therapy {
        public get()                    { return private_player_share_cnt_gene_therapy[this.index]; }
        public set(int value)           { private_player_share_cnt_gene_therapy[this.index] = value; }
    }

    property int receive_cnt_bandages {
        public get()                    { return private_player_receive_cnt_bandages[this.index]; }
        public set(int value)           { private_player_receive_cnt_bandages[this.index] = value; }
    }

    property int receive_cnt_first_aid {
        public get()                    { return private_player_receive_cnt_first_aid[this.index]; }
        public set(int value)           { private_player_receive_cnt_first_aid[this.index] = value; }
    }

    property int receive_cnt_pills {
        public get()                    { return private_player_receive_cnt_pills[this.index]; }
        public set(int value)           { private_player_receive_cnt_pills[this.index] = value; }
    }

    property int receive_cnt_gene_therapy {
        public get()                    { return private_player_receive_cnt_gene_therapy[this.index]; }
        public set(int value)           { private_player_receive_cnt_gene_therapy[this.index] = value; }
    }


    property int kill_cnt_total {
        public get()                    { return private_player_kill_cnt_total[this.index]; }
        public set(int value)           { private_player_kill_cnt_total[this.index] = value; }
    }

    property int kill_cnt_headSplit {
        public get()                    { return private_player_kill_cnt_headSplit[this.index]; }
        public set(int value)           { private_player_kill_cnt_headSplit[this.index] = value; }
    }

    property int kill_cnt_shambler {
        public get()                    { return private_player_kill_cnt_shambler[this.index]; }
        public set(int value)           { private_player_kill_cnt_shambler[this.index] = value; }
    }

    property int kill_cnt_runner {
        public get()                    { return private_player_kill_cnt_runner[this.index]; }
        public set(int value)           { private_player_kill_cnt_runner[this.index] = value; }
    }

    property int kill_cnt_kid {
        public get()                    { return private_player_kill_cnt_kid[this.index]; }
        public set(int value)           { private_player_kill_cnt_kid[this.index] = value; }
    }

    property int kill_cnt_turned {
        public get()                    { return private_player_kill_cnt_turned[this.index]; }
        public set(int value)           { private_player_kill_cnt_turned[this.index] = value; }
    }

    property int kill_cnt_player {
        public get()                    { return private_player_kill_cnt_player[this.index]; }
        public set(int value)           { private_player_kill_cnt_player[this.index] = value; }
    }

    property int kill_cnt_melee {
        public get()                    { return private_player_kill_cnt_melee[this.index]; }
        public set(int value)           { private_player_kill_cnt_melee[this.index] = value; }
    }

    property int kill_cnt_firearm {
        public get()                    { return private_player_kill_cnt_firearm[this.index]; }
        public set(int value)           { private_player_kill_cnt_firearm[this.index] = value; }
    }

    property int kill_cnt_explode {
        public get()                    { return private_player_kill_cnt_explode[this.index]; }
        public set(int value)           { private_player_kill_cnt_explode[this.index] = value; }
    }

    property int kill_cnt_flame {
        public get()                    { return private_player_kill_cnt_flame[this.index]; }
        public set(int value)           { private_player_kill_cnt_flame[this.index] = value; }
    }


    property int inflict_cnt_player {
        public get()                    { return private_player_inflict_cnt_player[this.index]; }
        public set(int value)           { private_player_inflict_cnt_player[this.index] = value; }
    }

    property int inflict_dmg_total {
        public get()                    { return private_player_inflict_dmg_total[this.index]; }
        public set(int value)           { private_player_inflict_dmg_total[this.index] = value; }
    }

    property int inflict_dmg_shambler {
        public get()                    { return private_player_inflict_dmg_shambler[this.index]; }
        public set(int value)           { private_player_inflict_dmg_shambler[this.index] = value; }
    }

    property int inflict_dmg_runner {
        public get()                    { return private_player_inflict_dmg_runner[this.index]; }
        public set(int value)           { private_player_inflict_dmg_runner[this.index] = value; }
    }

    property int inflict_dmg_kid {
        public get()                    { return private_player_inflict_dmg_kid[this.index]; }
        public set(int value)           { private_player_inflict_dmg_kid[this.index] = value; }
    }

    property int inflict_dmg_turned {
        public get()                    { return private_player_inflict_dmg_turned[this.index]; }
        public set(int value)           { private_player_inflict_dmg_turned[this.index] = value; }
    }

    property int inflict_dmg_player {
        public get()                    { return private_player_inflict_dmg_player[this.index]; }
        public set(int value)           { private_player_inflict_dmg_player[this.index] = value; }
    }

    property int inflict_dmg_melee {
        public get()                    { return private_player_inflict_dmg_melee[this.index]; }
        public set(int value)           { private_player_inflict_dmg_melee[this.index] = value; }
    }

    property int inflict_dmg_firearm {
        public get()                    { return private_player_inflict_dmg_firearm[this.index]; }
        public set(int value)           { private_player_inflict_dmg_firearm[this.index] = value; }
    }

    property int inflict_dmg_explode {
        public get()                    { return private_player_inflict_dmg_explode[this.index]; }
        public set(int value)           { private_player_inflict_dmg_explode[this.index] = value; }
    }

    property int inflict_dmg_flame {
        public get()                    { return private_player_inflict_dmg_flame[this.index]; }
        public set(int value)           { private_player_inflict_dmg_flame[this.index] = value; }
    }


    property int hurt_cnt_total {
        public get()                    { return private_player_hurt_cnt_total[this.index]; }
        public set(int value)           { private_player_hurt_cnt_total[this.index] = value; }
    }

    property int hurt_cnt_bleed {
        public get()                    { return private_player_hurt_cnt_bleed[this.index]; }
        public set(int value)           { private_player_hurt_cnt_bleed[this.index] = value; }
    }

    property int hurt_cnt_shambler {
        public get()                    { return private_player_hurt_cnt_shambler[this.index]; }
        public set(int value)           { private_player_hurt_cnt_shambler[this.index] = value; }
    }

    property int hurt_cnt_runner {
        public get()                    { return private_player_hurt_cnt_runner[this.index]; }
        public set(int value)           { private_player_hurt_cnt_runner[this.index] = value; }
    }

    property int hurt_cnt_kid {
        public get()                    { return private_player_hurt_cnt_kid[this.index]; }
        public set(int value)           { private_player_hurt_cnt_kid[this.index] = value; }
    }

    property int hurt_cnt_turned {
        public get()                    { return private_player_hurt_cnt_turned[this.index]; }
        public set(int value)           { private_player_hurt_cnt_turned[this.index] = value; }
    }

    property int hurt_cnt_player {
        public get()                    { return private_player_hurt_cnt_player[this.index]; }
        public set(int value)           { private_player_hurt_cnt_player[this.index] = value; }
    }

    property int hurt_dmg_total {
        public get()                    { return private_player_hurt_dmg_total[this.index]; }
        public set(int value)           { private_player_hurt_dmg_total[this.index] = value; }
    }

    property int hurt_dmg_bleed {
        public get()                    { return private_player_hurt_dmg_bleed[this.index]; }
        public set(int value)           { private_player_hurt_dmg_bleed[this.index] = value; }
    }

    property int hurt_dmg_shambler {
        public get()                    { return private_player_hurt_dmg_shambler[this.index]; }
        public set(int value)           { private_player_hurt_dmg_shambler[this.index] = value; }
    }

    property int hurt_dmg_runner {
        public get()                    { return private_player_hurt_dmg_runner[this.index]; }
        public set(int value)           { private_player_hurt_dmg_runner[this.index] = value; }
    }

    property int hurt_dmg_kid {
        public get()                    { return private_player_hurt_dmg_kid[this.index]; }
        public set(int value)           { private_player_hurt_dmg_kid[this.index] = value; }
    }

    property int hurt_dmg_turned {
        public get()                    { return private_player_hurt_dmg_turned[this.index]; }
        public set(int value)           { private_player_hurt_dmg_turned[this.index] = value; }
    }

    property int hurt_dmg_player {
        public get()                    { return private_player_hurt_dmg_player[this.index]; }
        public set(int value)           { private_player_hurt_dmg_player[this.index] = value; }
    }

    /**
     * 撤离、离开游戏、回合重启
     * 死亡为特殊情况: 初始加入, 死亡，中途复活
     */
    public void cleanup_stats() {
        // this.aready_submit_data     // * 只在复活时设为 false
        // this.steam_id               // * 只在玩家加入和获取授权时覆盖
        // this.put_in_time            // * 只在加入时覆盖
        // this.prefs                  // * 只在加入时覆盖
        // this.play_time              // * 当玩家在游戏中, 每隔一段时间都会更新
        this.spawn_time             = 0.0;

        this.taken_cnt_pills        = this.taken_cnt_gene_therapy   = this.effect_cnt_gene_therapy  =

        this.share_cnt_bandages     = this.share_cnt_first_aid      = this.share_cnt_pills          = this.share_cnt_gene_therapy   =
        this.receive_cnt_bandages   = this.receive_cnt_first_aid    = this.receive_cnt_pills        = this.receive_cnt_gene_therapy =

        this.kill_cnt_total         = this.kill_cnt_headSplit       = this.kill_cnt_shambler        = this.kill_cnt_runner          =
        this.kill_cnt_kid           = this.kill_cnt_turned          = this.kill_cnt_player          = this.kill_cnt_melee           =
        this.kill_cnt_firearm       = this.kill_cnt_explode         = this.kill_cnt_flame           =

        this.inflict_cnt_player     =
        this.inflict_dmg_total      = this.inflict_dmg_shambler     = this.inflict_dmg_runner       = this.inflict_dmg_kid          =
        this.inflict_dmg_turned     = this.inflict_dmg_player       = this.inflict_dmg_melee        = this.inflict_dmg_firearm      =
        this.inflict_dmg_explode    = this.inflict_dmg_flame        =


        this.hurt_cnt_total         = this.hurt_cnt_bleed           = this.hurt_cnt_shambler        = this.hurt_cnt_runner          =
        this.hurt_cnt_kid           = this.hurt_cnt_turned          = this.hurt_cnt_player          =
        this.hurt_dmg_total         = this.hurt_dmg_bleed           = this.hurt_dmg_shambler        = this.hurt_dmg_runner          =
        this.hurt_dmg_kid           = this.hurt_dmg_turned          = this.hurt_dmg_player          = 0;
    }
}


NRPlayerData nr_player_data[MAXPLAYERS + 1];


methodmap NRPlayerFunc __nullable__
{
    public NRPlayerFunc()  {
        return view_as<NRPlayerFunc>(true);
    }

    property float ff_factor {
        public get()                    { return cv_player_ff_factor; }
    }

    property float bleedout_dmg {
        public get()                    { return cv_player_bleedout_dmg; }
    }

    property float delay_show_play_time {
        public get()                    { return cv_player_connected_delay_time; }
    }

    property float play_time_interval {
        public get()                    { return cv_player_play_time_interval; }
    }

    public bool DMG_IsBleeding(float damage, int damagetype) {
        return ! FloatCompare(damage, cv_player_bleedout_dmg) && damagetype == DMG_RADIATION;
    }

    public bool DMG_IsInfected(float damage, int damagetype) {
        return ! FloatCompare(damage, 100.0) && damagetype == DMG_GENERIC;
    }


    public bool IsBleeding(int client) {
        return GetEntData(client, private_player_offset_bleedingOut, 1) == 1;
    }

    public bool IsInfected(int client) {
        return GetEntDataFloat(client, private_player_offset_InfectionTime) > 0.0 && FloatCompare(GetEntDataFloat(client, private_player_offset_InfectionDeathTime), GetGameTime()) == 1;
    }
    /**
     * 玩家首次进入服务器, 为其新增一条统计信息
     * 返回字符串, 可用于异步执行. Length = 51 - 2 + int
     * min: 59
     * recommend: 64
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            玩家的 client index
     *
     * @return                  No
     */
    public void insNewPlayerStats_sqlStr(char[] sql_str, int max_length, const int client) {
        FormatEx(sql_str, max_length, "INSERT IGNORE INTO player_stats(steam_id) VALUES(%d)", nr_player_data[client].steam_id);
    }

    /**
     * 记录新的玩家名字
     * 返回字符串, 可用于异步执行. Length = 82 - 4 + int + MAX_NAME_LENGTH
     * min: 216
     * recommend: 256
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param steam_id          玩家的 steam_id
     * @param name_escape       玩家名称 ( 转义后 )
     *
     * @return                  No
     */
    public void insNewPlayerName_sqlStr(char[] sql_str, int max_length, const int steam_id, const char[] name_escape) {
        FormatEx(sql_str, max_length, "INSERT INTO player_name VALUES (%d,'%s') ON DUPLICATE KEY UPDATE name=VALUES(name)", steam_id, name_escape);
    }


    /**
     * 记录回合数据
     * 返回字符串, 可用于异步执行.
     * [char(10) + int(1) * 3 + int(2) * 10 + int(3) * 17 + int(8) * 19  + float * 2] = 266
     * Length = 221 - 102 + 266
     * min: 385
     * recommend: 512
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param round_id          当前回合 id
     * @param client            玩家的 client index
     * @param time              事件发生的游戏时间
     *
     * @return                  No
     */
    public void insNewRoundData_sqlStr(char[] sql_str, int max_length, const int client, const float time, const char[] reason) {
        FormatEx(sql_str, max_length
            , "INSERT INTO round_data VALUES(null,%d,%d,'%s',%f,%f,%d,%d,%d,  %d,%d,%d,%d,%d,%d,%d,%d,  %d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,  %d,  %d,%d,%d,%d,%d,%d,%d,%d,%d,%d,  %d,%d,%d,%d,%d,%d,%d,  %d,%d,%d,%d,%d,%d,%d,NOW())"
            , nr_round.round_id,                            nr_player_data[client].steam_id,                reason,                                         time
            , nr_player_data[client].spawn_time,            nr_player_data[client].taken_cnt_pills,         nr_player_data[client].taken_cnt_gene_therapy,  nr_player_data[client].effect_cnt_gene_therapy
            , nr_player_data[client].share_cnt_bandages,    nr_player_data[client].share_cnt_first_aid,     nr_player_data[client].share_cnt_pills,         nr_player_data[client].share_cnt_gene_therapy
            , nr_player_data[client].receive_cnt_bandages,  nr_player_data[client].receive_cnt_first_aid,   nr_player_data[client].receive_cnt_pills,       nr_player_data[client].receive_cnt_gene_therapy
            , nr_player_data[client].kill_cnt_total,        nr_player_data[client].kill_cnt_headSplit,      nr_player_data[client].kill_cnt_shambler,       nr_player_data[client].kill_cnt_runner
            , nr_player_data[client].kill_cnt_kid,          nr_player_data[client].kill_cnt_turned,         nr_player_data[client].kill_cnt_player,         nr_player_data[client].kill_cnt_melee
            , nr_player_data[client].kill_cnt_firearm,      nr_player_data[client].kill_cnt_explode,        nr_player_data[client].kill_cnt_flame
            , nr_player_data[client].inflict_cnt_player
            , nr_player_data[client].inflict_dmg_total,     nr_player_data[client].inflict_dmg_shambler,    nr_player_data[client].inflict_dmg_runner,      nr_player_data[client].inflict_dmg_kid
            , nr_player_data[client].inflict_dmg_turned,    nr_player_data[client].inflict_dmg_player,      nr_player_data[client].inflict_dmg_melee
            , nr_player_data[client].inflict_dmg_firearm,   nr_player_data[client].inflict_dmg_explode,     nr_player_data[client].inflict_dmg_flame
            , nr_player_data[client].hurt_cnt_total,        nr_player_data[client].hurt_cnt_bleed,          nr_player_data[client].hurt_cnt_shambler,       nr_player_data[client].hurt_cnt_runner
            , nr_player_data[client].hurt_cnt_kid,          nr_player_data[client].hurt_cnt_turned,         nr_player_data[client].hurt_cnt_player
            , nr_player_data[client].hurt_dmg_total,        nr_player_data[client].hurt_dmg_bleed,          nr_player_data[client].hurt_dmg_shambler,       nr_player_data[client].hurt_dmg_runner
            , nr_player_data[client].hurt_dmg_kid,          nr_player_data[client].hurt_dmg_turned,         nr_player_data[client].hurt_dmg_player
        );
    }

    /**
     * 撤离、死亡、离开游戏、回合重启时, 累加玩家统计数据
     * 仅在离开时累加游戏时常
     * 返回字符串, 可用于异步执行. Length = 648 - 34 - 3 + int(1) * 4 + int(3) * 11 + int(5) * 1 + int(10) * 1
     * min: 669
     * recommend: 700
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            玩家的 client index
     * @param play_time         玩家在服务器内游玩时长(秒). 仅在离开游戏时 != 0
     * @param extracted         撤离次数
     *
     * @return                  No
     */
    public void updPlayerStats_sqlStr(char[] sql_str, int max_length, const int client, const int play_time=0, const int extracted=0) {
        FormatEx(sql_str, max_length
            , "UPDATE player_stats SET play_time=play_time+%d, extracted_cnt_total=extracted_cnt_total+%d,\
kill_cnt_total=kill_cnt_total+%d, kill_cnt_head=kill_cnt_head+%d, kill_cnt_shambler=kill_cnt_shambler+%d, kill_cnt_runner=kill_cnt_runner+%d, kill_cnt_kid=kill_cnt_kid+%d, kill_cnt_turned=kill_cnt_turned+%d,\
kill_cnt_player=kill_cnt_player+%d, kill_cnt_melee=kill_cnt_melee+%d, kill_cnt_firearm=kill_cnt_firearm+%d, kill_cnt_explode=kill_cnt_explode+%d, kill_cnt_flame=kill_cnt_flame+%d,\
taken_cnt_pills=taken_cnt_pills+%d, taken_cnt_gene_therapy=taken_cnt_gene_therapy+%d, effect_cnt_gene_therapy=effect_cnt_gene_therapy+%d WHERE steam_id=%d LIMIT 1"
            , play_time,                                        extracted
            , nr_player_data[client].kill_cnt_total,            nr_player_data[client].kill_cnt_headSplit,          nr_player_data[client].kill_cnt_shambler,           nr_player_data[client].kill_cnt_runner
            , nr_player_data[client].kill_cnt_kid,              nr_player_data[client].kill_cnt_turned,             nr_player_data[client].kill_cnt_player,             nr_player_data[client].kill_cnt_melee
            , nr_player_data[client].kill_cnt_firearm,          nr_player_data[client].kill_cnt_explode,            nr_player_data[client].kill_cnt_flame
            , nr_player_data[client].taken_cnt_pills,           nr_player_data[client].taken_cnt_gene_therapy,      nr_player_data[client].effect_cnt_gene_therapy,     nr_player_data[client].steam_id
        );
    }

    /**
     * 记录西瓜救援事件
     * 返回字符串, 可用于异步执行. Length = 57 - 6 + 2 * int + float
     * min: 86
     * recommend: 96
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            玩家 index
     *
     * @return                  No
     */
    public void insNewWatermelonRescue_sqlStr(char[] sql_str, int max_length, const int client) {
        FormatEx(sql_str, max_length, "INSERT INTO watermelon_rescue VALUES(NULL,%d,%f,%d,NOW())", nr_round.round_id, GetEngineTime(), nr_player_data[client].steam_id);
    }
}

bool LoadOffset_Player(char[] error, int err_max)
{
    if( (private_player_offset_bleedingOut          = FindSendPropInfo("CNMRiH_Player", "_bleedingOut")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::_bleedingOut'!");
        return false;
    }
    if( (private_player_offset_InfectionTime        = FindSendPropInfo("CNMRiH_Player", "m_flInfectionTime")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::m_flInfectionTime'!");
        return false;
    }
    if( (private_player_offset_InfectionDeathTime   = FindSendPropInfo("CNMRiH_Player", "m_flInfectionDeathTime")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::m_flInfectionDeathTime'!");
        return false;
    }
    return true;
}

void LoadConVar_Player()
{
    ConVar convar;
    (convar = FindConVar("sv_friendly_fire_factor")).AddChangeHook(OnConVarChange_Player);
    cv_player_ff_factor = convar.FloatValue;
    (convar = FindConVar("sv_bleedout_damage")).AddChangeHook(OnConVarChange_Player);
    cv_player_bleedout_dmg = convar.FloatValue;
    (convar = CreateConVar("sm_nr_player_connected_delay_time",     "5.0",  "玩家加入时, 延迟多少秒处理、记录、输出数据(立即处理容易出现 Error, 不建议修改)")).AddChangeHook(OnConVarChange_Player);
    cv_player_connected_delay_time = convar.FloatValue;
    (convar = CreateConVar("sm_nr_player_play_time_interval",       "60.0", "更新玩家游玩时长最短间隔(秒) | 建议为 sm_nr_global_timer_interval 的整数倍")).AddChangeHook(OnConVarChange_Player);
    cv_player_play_time_interval = convar.FloatValue;
}

void LoadHook_Player()
{
    HookEvent("player_spawn",               On_player_spawn,                        EventHookMode_Post);

    HookEvent("npc_killed",                 On_npc_killed,                          EventHookMode_Post);    // 无论何种方式击杀都会触发
    HookEvent("zombie_head_split",          On_zombie_head_split,                   EventHookMode_Post);    // 只在爆头击杀时触发
    HookEvent("zombie_killed_by_fire",      On_zombie_killed_by_fire,               EventHookMode_Post);

    HookEvent("player_extracted",           On_player_extracted,                    EventHookMode_Post);
    HookEvent("player_death",               On_player_death,                        EventHookMode_Post);

    HookEvent("player_leave",               On_player_leave,                        EventHookMode_Post);

    HookEvent("item_given",                 On_item_given,                          EventHookMode_Post);
    HookEvent("pills_taken",                On_pills_taken,                         EventHookMode_Post);
    HookEvent("vaccine_taken",              On_vaccine_taken,                       EventHookMode_Post);
}

void OnConVarChange_Player(ConVar convar, char[] old_value, char[] new_value)
{
    if( convar == INVALID_HANDLE )
    {
        return;
    }
    char convar_name[32];
    convar.GetName(convar_name, sizeof(convar_name));

    if( strcmp(convar_name, "sv_friendly_fire_factor") == 0 ) {
        cv_player_ff_factor = convar.FloatValue;
    }
    else if( strcmp(convar_name, "sv_bleedout_damage") == 0 ) {
        cv_player_bleedout_dmg = convar.FloatValue;
    }
    else if( strcmp(convar_name, "sm_nr_player_connected_delay_time") == 0 ) {
        cv_player_connected_delay_time = convar.FloatValue;
    }
    else if( strcmp(convar_name, "sm_nr_player_play_time_interval") == 0 ) {
        cv_player_play_time_interval = convar.FloatValue;
    }
}

stock bool IsValidClient(int client)
{
    return client <= MaxClients && client > 0 && IsClientInGame(client);
}


NRPlayerFunc nr_player_func;



