#pragma newdecls required
#pragma semicolon 1

ArrayList   protect_printer_extracted_rank;

bool        cv_printer_show_play_time
            , cv_printer_show_obj_chain_md5
            , cv_printer_show_wave_max
            , cv_printer_show_extraction_time
            , cv_printer_show_obj_start
            , cv_printer_show_wave_start
            , cv_printer_show_extraction_begin
            , cv_printer_show_player_extraction
            , cv_printer_show_watermelon_rescue;

float       cv_printer_delay_show_play_time
            , cv_printer_spawn_tolerance
            , cv_printer_spawn_penalty_factor;

void LoadConVar_Printer()
{
    ConVar convar;
    (convar = CreateConVar("sm_nr_printer_show_play_time",          "0",    "玩家加入时, 输出来源、在本服游玩时长")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_play_time = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_delay_show_play_time",    "5.0",  "玩家加入多少秒后输出、记录数据")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_delay_show_play_time = convar.FloatValue;
    (convar = CreateConVar("sm_nr_printer_show_extraction_time",    "0",    "回合开始时, 输出本回合最短/平均撤离耗时")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_extraction_time = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_obj_chain_md5",      "0",    "回合开始时, 输出本回合任务链的 MD5 Hash 值 (可用于区分不同路线)")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_obj_chain_md5 = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_obj_start",          "0",    "新任务开始时, 输出该任务信息")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_obj_start = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_wave_max",           "0",    "回合开始时, 输出本回合最大 wave 数")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_wave_max = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_wave_start",         "0",    "新 wave 开始时, 输出该 wave 信息")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_wave_start = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_extraction_begin",   "0",    "撤离开始时, 输出相关信息")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_extraction_begin = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_player_extraction",  "0",    "输出玩家撤离成功")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_player_extraction = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_watermelon_rescue",  "0",    "西瓜救援成功时, 输出相关信息")).AddChangeHook(OnConVarChange_Printer);
    cv_printer_show_watermelon_rescue = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_spawn_tolerance",         "10.0", "round_begin 后这么多秒内复活的玩家在计算通关时长时将被罚时")).AddChangeHook(OnConVarChange_Menu);
    cv_printer_spawn_tolerance = convar.FloatValue;
    (convar = CreateConVar("sm_nr_printer_spawn_penalty_factor",    "0.25", "额外罚时百分比. 最终结果 = (撤离时间 - round_begin) * (1.0 + value)")).AddChangeHook(OnConVarChange_Menu);
    cv_printer_spawn_penalty_factor = convar.FloatValue;
}

void OnConVarChange_Printer(ConVar convar, char[] old_value, char[] new_value)
{
    if( convar == INVALID_HANDLE )
        return ;
    char convar_name[64];
    convar.GetName(convar_name, sizeof(convar_name));
    if( strcmp(convar_name, "sm_nr_printer_show_play_time") == 0 ) {
        cv_printer_show_play_time = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_delay_show_play_time") == 0 ) {
        cv_printer_delay_show_play_time = convar.FloatValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_extraction_time") == 0 ) {
        cv_printer_show_extraction_time = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_obj_chain_md5") == 0 ) {
        cv_printer_show_obj_chain_md5 = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_obj_start") == 0 ) {
        cv_printer_show_obj_start = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_wave_max") == 0 ) {
        cv_printer_show_wave_max = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_wave_start") == 0 ) {
        cv_printer_show_wave_start = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_extraction_begin") == 0 ) {
        cv_printer_show_extraction_begin = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_player_extraction") == 0 ) {
        cv_printer_show_player_extraction = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_watermelon_rescue") == 0 ) {
        cv_printer_show_watermelon_rescue = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_spawn_tolerance") == 0 ) {
        cv_printer_spawn_tolerance = convar.FloatValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_spawn_penalty_factor") == 0 ) {
        cv_printer_spawn_penalty_factor = convar.FloatValue;
    }
}

methodmap NRPrinter __nullable__
{
    public NRPrinter()  {
        return view_as<NRPrinter>(true);
    }

    property bool show_play_time {
        public get()                            { return cv_printer_show_play_time; }
    }

    property float delay_show_play_time {
        public get()                            { return cv_printer_delay_show_play_time; }
    }

    property bool show_extraction_time {
        public get()                            { return cv_printer_show_extraction_time; }
    }

    property bool show_obj_chain_md5 {
        public get()                            { return cv_printer_show_obj_chain_md5; }
    }

    property bool show_obj_start {
        public get()                            { return cv_printer_show_obj_start; }
    }

    property bool show_wave_max {
        public get()                            { return cv_printer_show_wave_max; }
    }

    property bool show_wave_start {
        public get()                            { return cv_printer_show_wave_start; }
    }

    property bool show_extraction_begin {
        public get()                            { return cv_printer_show_extraction_begin; }
    }

    property bool show_player_extraction {
        public get()                            { return cv_printer_show_player_extraction; }
    }

    property bool show_watermelon_rescue {
        public get()                            { return cv_printer_show_watermelon_rescue; }
    }

    public void PrintWelcome(int client) {
        char sql_str[70];
        FormatEx(sql_str, sizeof(sql_str)
            // 52 - 2 + INT
            , "SELECT play_time FROM player_stats WHERE steam_id=%d LIMIT 1", nr_player_data[client].steam_id
            // 310 - 6 + INT * 3    // Custom Only
            // , "SELECT steam_id, SUM(play_time) play_time FROM (SELECT steam_id, play_time FROM nr_server1.player_stats WHERE steam_id=%d UNION ALL SELECT steam_id, play_time FROM nr_server2.player_stats WHERE steam_id=%d UNION ALL SELECT steam_id, play_time FROM nr_server3.player_stats WHERE steam_id=%d) t GROUP BY steam_id", steam_id, steam_id, steam_id
        );
        nr_dbi.db.Query(CB_asyncPrintWelcome, sql_str, GetClientUserId(client), DBPrio_Normal); // 特定回调
    }

    /**
     * 提前查询已记录的玩家撤离数据
     * 返回字符串, 可用于异步执行. Length = 220 - 4 + MAX_MAP_NAME_LEN + MAX_MD5_LEN
     * min: 300
     * recommend: 300
     *
     */
    public void PrintExtractedInfo() {
        char sql_str[512];
        FormatEx(sql_str, sizeof(sql_str)
            , "SELECT IF((spawn_time<=round_begin_time+%f), engine_time-round_begin_time, (engine_time-round_begin_time)*%f) AS take_time FROM map_info AS m INNER JOIN round_info AS r ON m.id=r.map_id INNER JOIN round_data AS d ON r.id=d.round_id WHERE m.map_name='%s' AND r.obj_chain_md5='%s' AND d.reason='extracted' ORDER BY take_time"
            , cv_printer_spawn_tolerance, 1.0 + cv_printer_spawn_penalty_factor, protect_map_map_name, protect_obj_chain_md5
        );
        nr_dbi.db.Query(CB_asyncPrintExtractedInfo, sql_str, _, DBPrio_Normal);   // 特定回调
    }

    public void PtintObjChainMD5(const char[] obj_chain_md5) {
        if( cv_printer_show_obj_chain_md5 ) {
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_OBJ_CHAIN_MD5 ) {
                    CPrintToChat(i, "%t", "Obj NMO ObjChainMD5", "Chat Head", obj_chain_md5);
                }
            }
        }
    }

    // * PrintObjStart

    public void PrintExtractionBegin(const float take_time) {
        int   take_time_minute  = RoundToFloor( take_time / 60.0 );
        float take_time_seconds = take_time % 60.0;

        if( nr_map.map_type == MAP_TYPE_NMO ) {             // [提示] 任务ID: {2} ({3}/{4}) | 信息: 任务完成, 快润! | 用时: [{5}:{6}]
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_EXTRACTION_BEGIN ) {
                    CPrintToChat(i, "%t", "Obj NMO OnExtractionBegin"
                        , "Chat Head",              objectiveChain.Get(objMgr.currentObjectiveIndex),   objMgr.currentObjectiveIndex + 1
                        , objectiveChain.Length,    take_time_minute,                                   take_time_seconds
                    );
                }
            }
        }
        else if( nr_map.map_type == MAP_TYPE_NMS ) {        // [提示] 信息: 救援已到, 快润! | 用时: [{5}:{6}]
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_EXTRACTION_BEGIN ) {
                    CPrintToChat(i, "%t", "Obj NMS OnExtractionBegin", "Chat Head", take_time_minute, take_time_seconds);
                }
            }
        }
    }

    public void PrintObjWaveMax(const int wave_length) {
        for(int i=1; i<=MaxClients; ++i) {
            if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_WAVE_MAX ) {
                CPrintToChat(i, "%t", "Obj NMS MaxWave", "Chat Head", protect_map_map_name, wave_length);
            }
        }

    }

    public void PrintNewWave(const int current_wave, const int wave_end, const int resupply) {
        if( wave_end != -1 ) {                              // 提示 wave: {2} / {3} (空投)
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_WAVE_START ) {
                    CPrintToChat(i, "%t", "Obj NMS OnNewWave", "Chat Head", current_wave, wave_end, resupply ? "Obj NMS OnNewWave Resupply" : "Obj NMS OnNewWave Null");
                }
            }
        }
        else if( current_wave != -1 ) {                     // 提示 wave: {2} (空投)
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_WAVE_START ) {
                    CPrintToChat(i, "%t", "Obj NMS OnNewWave NoEndWave", "Chat Head", current_wave, resupply ? "Obj NMS OnNewWave Resupply" : "Obj NMS OnNewWave Null");
                }
            }
        }
    }

    public void PrintPlayerExtraction(const int client, const float engine_time) {
        float take_time = engine_time - nr_round.begin_time;
        float penalty_time = nr_player_data[client].spawn_time <= (nr_round.begin_time + cv_printer_spawn_tolerance) ? 0.0 : take_time * cv_printer_spawn_penalty_factor;
        float final_time = take_time + penalty_time;

        int rank_id = 0;
        if( protect_printer_extracted_rank.Length == 0 ) {
            protect_printer_extracted_rank.Push(final_time);
        }
        else {
            for( ; rank_id < protect_printer_extracted_rank.Length; ++rank_id) {
                if( FloatCompare(final_time, protect_printer_extracted_rank.Get(rank_id)) <= 0 ) {
                    break;
                }
            }
            if( rank_id < protect_printer_extracted_rank.Length ) {
                protect_printer_extracted_rank.ShiftUp(rank_id);
                protect_printer_extracted_rank.Set(rank_id, final_time);
            }
            else {
                protect_printer_extracted_rank.Push(final_time);
            }
        }

        int   take_time_minute  = RoundToFloor( final_time / 60.0 );
        float take_time_seconds = final_time % 60.0;
        if( penalty_time == 0.0 )
        {
            // "[提示]{name} 撤离成功! 用时: {green}{min}:{sec}{default}  | 排名: {green}{5}{default}"
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_PLAYER_EXTRACTION ) {
                    CPrintToChat(i, "%t", "Player OnPlayer_Extracted", "Chat Head", client, rank_id + 1, take_time_minute, take_time_seconds);
                }
            }
        }
        else
        {
            int   penalty_minute    = RoundToFloor( penalty_time / 60.0 );
            float penalty_seconds   = penalty_time % 60.0;
            // "[提示]{name} 撤离成功! 用时: {green}{min}:{sec}{default}  | 排名: {green}{5}{default}"
            for(int i=1; i<=MaxClients; ++i) {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_PLAYER_EXTRACTION ) {
                    CPrintToChat(i, "%t", "Player OnPlayer_Extracted Penalty", "Chat Head", client, rank_id + 1, take_time_minute, take_time_seconds, penalty_minute, penalty_seconds);
                }
            }
        }
    }

    public void PrintWatermelonRescue(const int client) {
        for(int i=1; i<=MaxClients; ++i) {
            if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_WATERMELON_RESCURE ) {
                CPrintToChat(i, "%t", "Obj OnWatermelonRescue", "Chat Head", client);
            }
        }
    }
}

NRPrinter nr_printer;


public void PrintObjStart(DataPack data)
{
    char text[MAX_OBJNOTIFY_LEN];
    data.Reset();
    data.ReadString(text, MAX_OBJNOTIFY_LEN);
    delete data;
    for(int i=1; i<=MaxClients; ++i) {
        if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_OBJ_START ) {
            CPrintToChat(i, "%t", "Obj NMO OnObjStart", "Chat Head", nr_objective.obj_id, nr_objective.obj_serial, nr_objective.obj_chain_len, text);
        }
    }
}


void CB_asyncPrintWelcome(Database db, DBResultSet results, const char[] error, int user_id)
{
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' )
    {
        int client = GetClientOfUserId(user_id);
        if( client && ! IsClientInGame(client) )
        {
            return ;
        }

        float play_time_hours = 0.0;
        if( results.FetchRow() )
        {
            play_time_hours = results.FetchInt(0) / 60.0 / 60.0 ;
        }

        char ip[32], country[32], region[32];
        GetClientIP(client, ip, sizeof(ip));
        for(int i=1; i<=MaxClients; ++i)
        {
            if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_WELCOME )
            {
                if( GeoipCountryEx(ip, country, sizeof(country), i) || GeoipRegion(ip, region, sizeof(region), i) )
                {
                    CPrintToChat(i, "%T", "Player PlayTime_Region", i, "Chat Head", country, region, client, play_time_hours);
                }
                else
                {
                    CPrintToChat(i, "%T", "Player PlayTime", i, "Chat Head", country, region, client, play_time_hours);
                }
            }
        }
    }
    else
    {
        LogError(PREFIX_DBI..."CB_asyncPrintWelcome | db:%d | result:%d | Error: %s |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
    }
}

void CB_asyncPrintExtractedInfo(Database db, DBResultSet results, const char[] error, any data)
{
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' )
    {
        float t_take_time, sum_time;
        while( results.FetchRow() )
        {
            t_take_time = results.FetchFloat(0);
            sum_time += t_take_time;
            protect_printer_extracted_rank.Push(t_take_time);
        }

        if( protect_printer_extracted_rank.Length <= 0 )
        {
            for(int i=1; i<=MaxClients; ++i)
            {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_EXTRACTION_RANK )
                {
                    CPrintToChat(i, "%t", "Obj Extracted_Info_NoOne", "Chat Head");
                }
            }
        }
        else
        {
            float avg_time = sum_time / protect_printer_extracted_rank.Length;
            int   avg_time_minute   = RoundToFloor( avg_time / 60.0 );
            float avg_time_seconds  = avg_time % 60.0;
            float fast_time = protect_printer_extracted_rank.Get(0);
            int   fast_time_minute  = RoundToFloor( fast_time / 60.0 );
            float fast_time_seconds = fast_time % 60.0;
            for(int i=1; i<=MaxClients; ++i)
            {
                if( IsClientInGame(i) && nr_player_data[i].prefs & CLIENT_PREFS_BIT_SHOW_EXTRACTION_RANK )
                {
                    CPrintToChat(i, "%t", "Obj Extracted_Info", "Chat Head", protect_printer_extracted_rank.Length, fast_time_minute, fast_time_seconds, avg_time_minute, avg_time_seconds);
                }
            }
        }
    }
    else
    {
        LogError(PREFIX_DBI..."CB_asyncPrintExtractedInfo | db:%d | result:%d | Error: %s |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
    }
}
