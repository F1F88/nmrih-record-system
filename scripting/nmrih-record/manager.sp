#pragma newdecls required
#pragma semicolon 1

#define PREFIX_MANAGER "[NR-Manager]"

methodmap NRManager __nullable__
{
    public NRManager()  {
        return view_as<NRManager>(true);
    }


    /**
     * 记录新的玩家来源 (用于管理服务器秩序)
     * 返回字符串, 可用于异步执行. Length = 119 - 14 + 2 * int + 64 + 4 * 32
     * min: 205
     * recommend: 200
     *
     * @param db                数据库对象. 用于转义字符串
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            玩家的 client index
     *
     * @return                  No
     * @error                   Invalid database handle Or prepare failure
     */
    public void insNewPlayerPutIn_sqlStr(Database db, char[] sql_str, int max_length, const int client) {
        if( db == INVALID_HANDLE ) {
            ThrowError(PREFIX_PLAYER..."insNewPlayerPutIn_sqlStr Database == INVALID_HANDLE");
        }

        char ip[32],                    ip_escape[32];
        char country[32],               country_escape[32];
        char continent[32],             continent_escape[32];
        char region[32],                region_escape[32];
        char city[32],                  city_escape[32];

        GetClientIP(    client,         ip,                     sizeof(ip));
        GeoipCountryEx( ip,             country,                sizeof(country),            LANG_SERVER);
        GeoipContinent( ip,             continent,              sizeof(continent),          LANG_SERVER);
        GeoipRegion(    ip,             region,                 sizeof(region),             LANG_SERVER);
        GeoipCity(      ip,             city,                   sizeof(city),               LANG_SERVER);
        db.Escape(      ip,             ip_escape,              sizeof(ip_escape));
        db.Escape(      country,        country_escape,         sizeof(country_escape));
        db.Escape(      continent,      continent_escape,       sizeof(continent_escape));
        db.Escape(      region,         region_escape,          sizeof(region_escape));
        db.Escape(      city,           city_escape,            sizeof(city_escape));

        FormatEx(sql_str, max_length
            , "INSERT INTO player_put_in SET round_id=%d, steam_id=%d, `ip`='%s', country='%s', continent='%s', region='%s', city='%s'"
            , nr_round.round_id,    GetSteamAccountID(client),    ip_escape,    country_escape,    continent_escape,    region_escape,    city_escape
        );
    }

    /**
     * 记录新的玩家受伤事件
     * 返回字符串, 可用于异步执行. Length = 130 - 16 + 5 * int + float + MAX_WEAPON_LEN
     * min: 201
     * recommend: 200
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param victim_id         受害者的 SteamAccountID
     * @param attacker_id       攻击者的 ID (玩家时为 SteamAccountID, 其他为实体 index)
     * @param weapon_name       武器名称 (常规: player、***zombie | 特殊值: _bleed, _infected, _self)
     * @param damage            实际造成的伤害
     * @param damageType        造成的伤害类型
     *
     * @return                  No
     */
    public void insNewPlayerHurt_sqlStr(char[] sql_str, int max_length, const int victim_id, const int attacker_id, const char[] weapon_name, const int damage, const int damageType) {
        FormatEx(sql_str, max_length
            , "INSERT INTO player_hurt SET round_id=%d, engine_time=%f, victim_id=%d, attacker_id=%d, weapon_name='%s', damage=%d, damage_type=%d"
            , nr_round.round_id,    GetEngineTime(),    victim_id,    attacker_id,    weapon_name,    damage,    damageType
        );
    }

    /**
     * 记录玩家离开
     * 返回字符串, 可用于异步执行. Length = 101 - 12 + 3 * int + MAX_NAME_LENGTH + 32
     * min: 274
     * recommend: 292
     *
     * @param db                数据库对象. 用于转义字符串
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            client
     * @param reason            reason the player left the server
     * @param networkid         player network (i.e steam) id
     * @param play_time         Play time on the server
     *
     * @return                  No
     * @error                   Invalid database handle Or prepare failure
     */
    public void insNewPlayerDisconnect_sqlStr(Database db, char[] sql_str, int max_length, const int client, const char[] reason, const char[] networkid, const int play_time) {
        if( db == INVALID_HANDLE )
        {
            ThrowError(PREFIX_MANAGER..."insNewPlayerDisconnect_sqlStr Database == INVALID_HANDLE");
        }

        char reason_escape[MAX_NAME_LENGTH],        networkid_escape[32];

        db.Escape(reason,       reason_escape,      sizeof(reason_escape));
        db.Escape(networkid,    networkid_escape,   sizeof(networkid_escape));

        FormatEx(sql_str,       max_length
            , "INSERT INTO player_disconnect SET round_id=%d, steam_id=%d, reason='%s', networkid='%s', play_time=%d"
            , nr_round.round_id,    nr_player_data[client].steam_id,    reason_escape,    networkid_escape,    play_time
        );
    }

    /**
     * 记录玩家发言
     * 返回字符串, 可用于异步执行. Length = 62 - 3 + 2 * int + 256
     * min: 335
     * recommend: 350
     *
     * @param db                数据库对象, 用于转义玩家发言文本
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            client
     * @param text              玩家发言文本 (未转义)
     *
     * @return                  No
     * @error                   Invalid database handle Or prepare failure
     */
    public void insNewPlayerSay_sqlStr(Database db, char[] sql_str, int max_length, const int client, const char[] text) {
        if( db == INVALID_HANDLE )
        {
            ThrowError(PREFIX_MANAGER..."insNewPlayerSay_sqlStr Database == INVALID_HANDLE");
        }
        char text_escape[300];
        db.Escape(text, text_escape, sizeof(text_escape));

        FormatEx(sql_str, max_length, "INSERT INTO player_say SET round_id=%d, steam_id=%d, text='%s'", nr_round.round_id, nr_player_data[client].steam_id, text_escape);
    }

    /**
     * 记录发起投票信息 (管理滥用踢人)
     * 返回字符串, 可用于异步执行. Length = 66 - 6 + 2 * int + 32
     * min: 112
     * recommend: 128
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param map_id            地图 id
     * @param round_id          回合 id
     * @param steam_id          steam account id
     * @param vote_info         发起的投票信息
     *
     * @return                  No
     */
    public void insNewCallVote_sqlStr(char[] sql_str, int max_length, const int client, const char[] vote_info) {
        FormatEx(sql_str, max_length, "INSERT INTO vote_info SET round_id=%d, steam_id=%d, vote_info='%s'", nr_round.round_id, nr_player_data[client].steam_id, vote_info);
    }

    /**
     * 记录投票选择信息 (管理滥用踢人)
     * 返回字符串, 可用于异步执行. Length = 66 - 6 + 2 * int + bool
     * min: 82
     * recommend: 84
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param map_id            地图 id
     * @param round_id          回合 id
     * @param steam_id          steam account id
     * @param vote_option       玩家做出的选项
     *
     * @return                  No
     */
    public void insNewVoteCast_sqlStr(char[] sql_str, int max_length, const int client, const int vote_option) {
        FormatEx(sql_str, max_length, "INSERT INTO vote_info SET round_id=%d, steam_id=%d, vote_option=%d", nr_round.round_id, nr_player_data[client].steam_id, vote_option);
    }
}

void LoadHook_Manager()
{
    HookEvent("player_say",             On_player_say,              EventHookMode_Post);
    HookEvent("player_disconnect",      On_player_disconnect,       EventHookMode_Post);
    HookEvent("vote_cast",              On_vote_cast,               EventHookMode_Post);
    AddCommandListener(On_call_vote,    "callvote");
}


NRManager nr_manager;


// * manager
// 触发 玩家发言
void On_player_say(Event event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    char text[256];
    event.GetString("text", text, sizeof(text));

    char sql_str[384];
    nr_manager.insNewPlayerSay_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), client, text);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
}

// 触发 发起投票
public Action On_call_vote(int client, const char[] command, int argc)
{
    if( argc < 1 )  // 呼出投票菜单
    {
        return Plugin_Continue;
    }
    char vote_info[32];
    GetCmdArg(1, vote_info, sizeof(vote_info));

    char sql_str[128];
    nr_manager.insNewCallVote_sqlStr(sql_str, sizeof(sql_str), client, vote_info);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);

    return Plugin_Continue;
}

// 触发 玩家选择投票
public void On_vote_cast(Event event, char[] name, bool dontBroadcast)
{
    char sql_str[84];
    nr_manager.insNewVoteCast_sqlStr(sql_str, sizeof(sql_str), event.GetInt("entityid"), event.GetInt("vote_option"));
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
}
