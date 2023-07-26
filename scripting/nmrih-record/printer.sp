#pragma newdecls required
#pragma semicolon 1

ArrayList   protect_printer_extracted_rank;

bool        cv_printer_show_play_time
            , cv_printer_show_obj_chain_md5
            , cv_printer_show_wave_max
            , cv_printer_show_extraction_time
            , cv_printer_show_new_obj_start
            , cv_printer_show_new_wave_start
            , cv_printer_show_extraction_begin
            , cv_printer_show_player_extraction
            , cv_printer_show_watermelon_rescue;

float       cv_printer_delay_show_play_time;

void LoadPrinterConVar()
{
    ConVar convar;
    (convar = CreateConVar("sm_nr_printer_show_play_time",          "0",    "玩家加入时, 输出来源、在本服游玩时长")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_play_time = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_delay_show_play_time",    "5.0",  "玩家加入多少秒后输出、记录数据")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_delay_show_play_time = convar.FloatValue;
    (convar = CreateConVar("sm_nr_printer_show_extraction_time",    "0",    "回合开始时, 输出本回合最短/平均撤离耗时")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_extraction_time = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_obj_chain_md5",      "0",    "回合开始时, 输出本回合任务链的 MD5 Hash 值 (可用于区分不同路线)")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_obj_chain_md5 = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_obj_start",          "0",    "新任务开始时, 输出该任务信息")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_new_obj_start = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_wave_max",           "0",    "回合开始时, 输出本回合最大 wave 数")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_wave_max = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_wave_start",         "0",    "新wave开始时, 输出该wave信息")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_new_wave_start = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_extraction_begin",   "0",    "撤离开始时, 输出相关信息")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_extraction_begin = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_player_extraction",  "0",    "输出玩家撤离成功")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_player_extraction = convar.BoolValue;
    (convar = CreateConVar("sm_nr_printer_show_watermelon_rescue",  "0",    "西瓜救援成功时, 输出相关信息")).AddChangeHook(OnPrinterConVarChange);
    cv_printer_show_watermelon_rescue = convar.BoolValue;
}

void OnPrinterConVarChange(ConVar convar, char[] old_value, char[] new_value)
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
        cv_printer_show_new_obj_start = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_wave_max") == 0 ) {
        cv_printer_show_wave_max = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_printer_show_wave_start") == 0 ) {
        cv_printer_show_new_wave_start = convar.BoolValue;
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
}

methodmap NRPrinter __nullable__
{
    public NRPrinter()  {
        return view_as<NRPrinter>(true);
    }

    public void PrintPlayTime(int client, int steam_id) {
        if( cv_printer_show_play_time ) {
            char sql_str[64];   // 52 - 2 + INT
            FormatEx(sql_str, sizeof(sql_str), "SELECT play_time FROM player_stats WHERE steam_id=%d", steam_id);
            nr_dbi.db.Query(CB_asyncGetPlayTime, sql_str, client, DBPrio_Normal); // 特定回调
        }
    }

    public void PrintExtractedAvgTime() {
        if( cv_printer_show_extraction_time ) {             // 提前查询已记录的玩家撤离数据
            // 220 - 4 + MAX_MAP_NAME_LEN + MAX_MD5_LEN     // min: 300             // recommend: 300
            char sql_str[350];
            FormatEx(sql_str, sizeof(sql_str)
                , "SELECT d.engine_time-r.round_begin_time FROM map_info AS m INNER JOIN round_info AS r ON m.id=r.map_id INNER JOIN round_data AS d ON r.id=d.round_id WHERE m.map_name='%s' AND r.obj_chain_md5='%s' AND d.reason='extracted'"
                , protect_map_map_name, protect_obj_chain_md5
            );
            nr_dbi.db.Query(CB_asyncGetExtractedRank, sql_str, _, DBPrio_Normal);   // 特定回调
        }
    }

    public void PtintObjChainMD5(const char[] obj_chain_md5) {
        if( cv_printer_show_obj_chain_md5 ) {
            CPrintToChatAll("%t", "Obj NMO ObjChainMD5", "HEAD", obj_chain_md5);
        }
    }

    // PrintObjStart

    public void PrintExtractionBegin(const float take_time) {
        if( cv_printer_show_extraction_begin ) {
            int   take_time_minute  = RoundToFloor( take_time / 60.0 );
            float take_time_seconds = take_time % 60.0;

            if( nr_map.map_type == MAP_TYPE_NMO ) {             // [提示] 任务ID: {2} ({3}/{4}) | 信息: 任务完成, 快润! | 用时: [{5}:{6}]
                CPrintToChatAll("%t", "Obj NMO OnExtractionBegin"
                    , "HEAD",                   objectiveChain.Get(objMgr.currentObjectiveIndex),   objMgr.currentObjectiveIndex + 1
                    , objectiveChain.Length,    take_time_minute,                                   take_time_seconds
                );
            }
            else if( nr_map.map_type == MAP_TYPE_NMS ) {        // [提示] 信息: 救援已到, 快润! | 用时: [{5}:{6}]
                CPrintToChatAll("%t", "Obj NMS OnExtractionBegin", "HEAD", take_time_minute, take_time_seconds);
            }
        }
    }

    public void PrintObjWaveMax(const int wave_length) {
        if( cv_printer_show_wave_max ) {
            CPrintToChatAll("%t", "Obj NMS MaxWave", "HEAD", protect_map_map_name, wave_length);
        }
    }

    public void PrintNewWave(const int current_wave, const int wave_end, const int resupply) {
        if( cv_printer_show_new_wave_start ) {
            if( wave_end != -1 ) {                              // 提示 wave: {2} / {3} (空投)
                CPrintToChatAll("%t", "Obj NMS OnNewWave", "HEAD", current_wave, wave_end, resupply ? "Obj NMS OnNewWave Resupply" : "Obj NMS OnNewWave Null");
            }
            else if( current_wave != -1 ) {                     // 提示 wave: {2} (空投)
                CPrintToChatAll("%t", "Obj NMS OnNewWave NoEndWave", "HEAD", current_wave, resupply ? "Obj NMS OnNewWave Resupply" : "Obj NMS OnNewWave Null");
            }

        }
    }

    public void PrintPlayerExtraction(const int client, const float take_time) {
        if( cv_printer_show_player_extraction ) {
            int   take_time_minute  = RoundToFloor( take_time / 60.0 );
            float take_time_seconds = take_time % 60.0;

            int rank_id = 0;
            if( protect_printer_extracted_rank.Length == 0 ) {
                protect_printer_extracted_rank.Push(take_time);
            }
            else {
                for( ; rank_id < protect_printer_extracted_rank.Length; ++rank_id) {
                    if( FloatCompare(take_time, protect_printer_extracted_rank.Get(rank_id)) <= 0 ) {
                        break;
                    }
                }
                if( rank_id < protect_printer_extracted_rank.Length ) {
                    protect_printer_extracted_rank.ShiftUp(rank_id);
                    protect_printer_extracted_rank.Set(rank_id, take_time);
                }
                else {
                    protect_printer_extracted_rank.Push(take_time);
                }
            }

            // "[提示]{name} 撤离成功! 用时: {green}{min}:{sec}{default}  | 排名: {green}{5}{default}"
            CPrintToChatAll("%t", "Player OnPlayer_Extracted", "HEAD", client, take_time_minute, take_time_seconds, rank_id + 1);
        }
    }

    public void PrintWatermelonRescue(const int client) {
        if( cv_printer_show_watermelon_rescue ) {
            CPrintToChatAll("%t", "Obj OnWatermelonRescue", "HEAD", client);
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
    CPrintToChatAll("%t", "Obj NMO OnObjStart", "HEAD", nr_objective.obj_id, nr_objective.obj_serial, nr_objective.obj_chain_len, text);
}


void CB_asyncGetPlayTime(Database db, DBResultSet results, const char[] error, int client)
{
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' )
    {
        float play_time_hours = 0.0;
        if( results.FetchRow() )
        {
            play_time_hours = results.FetchInt(0) / 60.0 / 60.0 ;
        }

        char ip[32], country[32], region[32];
        GetClientIP(client, ip, sizeof(ip));
        for(int i=1; i<=MaxClients; ++i)
        {
            if( IsClientInGame(i) )
            {
                if( GeoipCountryEx(ip, country, sizeof(country), i) || GeoipRegion(ip, region, sizeof(region), i) )
                {
                    CPrintToChat(i, "%T", "Player PlayTime_Region", i, "HEAD", country, region, client, play_time_hours);
                }
                else
                {
                    CPrintToChat(i, "%T", "Player PlayTime", i, "HEAD", country, region, client, play_time_hours);
                }
            }
        }
    }
    else
    {
        LogError(PREFIX_DBI..."CB_asyncGetPlayTime | db:%d | result:%d | Error: %s |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
    }
}

void CB_asyncGetExtractedRank(Database db, DBResultSet results, const char[] error, int client)
{
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' )
    {
        float tmp, sum_time, avg_time = 0.0;
        while( results.FetchRow() )
        {
            tmp = results.FetchFloat(0);
            sum_time += tmp;
            protect_printer_extracted_rank.Push(tmp);
        }
        if( protect_printer_extracted_rank.Length <= 0 )
        {
            CPrintToChatAll("%t", "Obj Extracted_Taketime_NoOne", "HEAD");
        }
        else
        {
            protect_printer_extracted_rank.Sort(Sort_Ascending, Sort_Float);
            avg_time = sum_time / protect_printer_extracted_rank.Length;
            int   avg_time_minute   = RoundToFloor( avg_time / 60.0 );
            float avg_time_seconds  = avg_time % 60.0;
            float fast_time = protect_printer_extracted_rank.Get(0);
            int   fast_time_minute  = RoundToFloor( fast_time / 60.0 );
            float fast_time_seconds = fast_time % 60.0;
            CPrintToChatAll("%t", "Obj Extracted_Taketime", "HEAD", fast_time_minute, fast_time_seconds, avg_time_minute, avg_time_seconds, protect_printer_extracted_rank.Length);
        }
    }
    else
    {
        LogError(PREFIX_DBI..."CB_asyncGetExtractedRank | db:%d | result:%d | Error: %s |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
    }
}
