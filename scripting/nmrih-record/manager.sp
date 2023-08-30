#pragma newdecls required
#pragma semicolon 1

#define PREFIX_MANAGER "[NR-Manager]"


int private_manager_vote_id;

methodmap NRManager __nullable__
{
    public NRManager()  {
        return view_as<NRManager>(true);
    }


    /**
     * 记录新的玩家来源 (用于管理服务器秩序)
     * 返回字符串, 可用于异步执行. Length = 92 - 16 + int * 2 + 64 + char(32) * 4 + MAX_NAME_LENGTH
     * min: 360
     * recommend: 384
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param steam_id          玩家的 steam_id
     * @param name_escape       玩家名称 (需提前转义)
     * @param ip_escape         ip 地址 (需提前转义)
     * @param country_escape    地区 (需提前转义)
     * @param continent_escape  地区 (需提前转义)
     * @param region_escape     地区 (需提前转义)
     * @param city_escape       城市 (需提前转义)
     * @param create_time       加入时间
     *
     * @return                  No
     * @error                   Invalid database handle Or prepare failure
     */
    public void insNewPlayerPutIn_sqlStr(char[] sql_str, int max_length, const int steam_id, const char[] name_escape, const char[] ip_escape, const char[] country_escape, const char[] continent_escape, const char[] region_escape, const char[] city_escape, const int create_time) {
        FormatEx(sql_str, max_length, "INSERT INTO player_put_in VALUES(NULL,%d,%d,'%s','%s','%s','%s','%s','%s',FROM_UNIXTIME(%d))", nr_round.round_id, steam_id, name_escape, ip_escape, country_escape, continent_escape, region_escape, city_escape, create_time);
    }

    /**
     * 记录新的玩家受伤事件
     * 返回字符串, 可用于异步执行. Length = 65 - 14 + 5 * int + float + MAX_WEAPON_LEN
     * min: 148
     * recommend: 160
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
        FormatEx(sql_str, max_length, "INSERT INTO player_hurt VALUES(NULL,%d,%f,%d,%d,'%s',%d,%d,NOW())", nr_round.round_id, GetEngineTime(), victim_id, attacker_id, weapon_name, damage, damageType);
    }

    /**
     * 记录玩家离开
     * 返回字符串, 可用于异步执行. Length = 67 - 10 + int(10) * 2 + MAX_NAME_LENGTH + 32
     * min: 237
     * recommend: 256
     *
     * @param db                数据库对象. 用于转义字符串
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            client
     * @param reason_escape     reason the player left the server
     * @param reason_escape     player network (i.e steam) id
     * @param play_time         Play time on the server
     *
     * @return                  No
     * @error                   Invalid database handle Or prepare failure
     */
    public void insNewPlayerDisconnect_sqlStr(char[] sql_str, int max_length, const int client, const char[] reason_escape, const char[] networkid_escape, const int play_time) {
        FormatEx(sql_str, max_length, "INSERT INTO player_disconnect VALUES(NULL,%d,%d,'%s','%s',%f,NOW())", nr_round.round_id, nr_player_data[client].steam_id, reason_escape, networkid_escape, play_time);
    }

    /**
     * 记录玩家发言
     * 返回字符串, 可用于异步执行. Length = 52 - 6 + 2 * int + 256
     * min: 322
     * recommend: 512
     *
     * @param db                数据库对象, 用于转义玩家发言文本
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            client
     * @param text_escape       玩家发言文本 (需提前转义)
     *
     * @return                  No
     * @error                   Invalid database handle Or prepare failure
     */
    public void insNewPlayerSay_sqlStr(char[] sql_str, int max_length, const int client, const char[] text_escape) {
        FormatEx(sql_str, max_length, "INSERT INTO player_say VALUES(null,%d,%d,'%s',NOW())", nr_round.round_id, nr_player_data[client].steam_id, text_escape);
    }

    /**
     * 记录发起投票信息 (管理滥用踢人)
     * 返回字符串, 可用于异步执行. Length = 53 - 6 + 2 * int + 32
     * min: 100
     * recommend: 100
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            client index
     * @param vote_info         发起的投票信息
     *
     * @return                  No
     */
    public void insNewCallVote_sqlStr(char[] sql_str, int max_length, const int client, const char[] vote_info) {
        FormatEx(sql_str, max_length, "INSERT INTO vote_submit VALUES(null,%d,%d,'%s',NOW())", nr_round.round_id, nr_player_data[client].steam_id, vote_info);
    }

    /**
     * 记录投票选择信息 (管理滥用踢人)
     * 返回字符串, 可用于异步执行. Length = 51 - 6 + 2 * int + bool
     * min: 70
     * recommend: 70
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param client            client index
     * @param vote_option       玩家做出的选项
     *
     * @return                  No
     */
    public void insNewVoteCast_sqlStr(char[] sql_str, int max_length, const int client, const int vote_option) {
        FormatEx(sql_str, max_length, "INSERT INTO vote_option VALUES(null,%d,%d,%d,NOW())", private_manager_vote_id, nr_player_data[client].steam_id, vote_option);
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

    char sql_str[512];
    char text[256],                     text_escape[448];
    event.GetString("text",             text,                       sizeof(text));
    nr_dbi.db.Escape(text,              text_escape,                sizeof(text_escape));

    nr_manager.insNewPlayerSay_sqlStr(sql_str, sizeof(sql_str), client, text_escape);
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

    char sql_str[100];
    nr_manager.insNewCallVote_sqlStr(sql_str, sizeof(sql_str), client, vote_info);
    nr_dbi.db.Query(CB_asyncManagerSaveVoteInfo, sql_str, _, DBPrio_High);

    return Plugin_Continue;
}

void CB_asyncManagerSaveVoteInfo(Database db, DBResultSet results, const char[] error, any data)
{
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' )
    {
        private_manager_vote_id = SQL_GetInsertId(db);
    }
    else
    {
        LogError(PREFIX_DBI..."CB_asyncManagerSaveVoteInfo | db:%d | result:%d | Error: %s |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
    }
}

// 触发 玩家选择投票
public void On_vote_cast(Event event, char[] name, bool dontBroadcast)
{
    DataPack data = new DataPack();
    CreateDataTimer(2.0, Timer_ManagerVoteCast, data, TIMER_DATA_HNDL_CLOSE);
    data.WriteCell(event.GetInt("entityid"));                       // client
    data.WriteCell(event.GetInt("vote_option"));                    // vote_option
}

Action Timer_ManagerVoteCast(Handle timer, DataPack data)
{
    data.Reset();
    int client = data.ReadCell();
    int vote_option = data.ReadCell();
    char sql_str[70];
    nr_manager.insNewVoteCast_sqlStr(sql_str, sizeof(sql_str), client, vote_option);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
    return Plugin_Stop;
}
