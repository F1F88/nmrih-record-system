// Todo: 在地图、回合信息记录失败时停止记录
// Todo: 补充使用绷带和医疗包事件及记录字段
// Todo: Top菜单支持查看完整通关数据
// Todo: 删除 manager 工厂

#pragma newdecls required
#pragma semicolon 1

#define  INCLUDE_MANAGER
#define  NR_VERSION                 "v1.0.1"

#include <sourcemod>
#include <dbi>
#include <geoip>
#include <sdktools>
#include <sdkhooks>

#undef   REQUIRE_EXTENSIONS
#include <clientprefs>
#define  REQUIRE_EXTENSIONS

#include <multicolors>
#include <vscript_proxy>
#include <smlib/crypt>

#include "nmrih-record/dbi.sp"
#include "nmrih-record/map.sp"
#include "nmrih-record/round.sp"
#include "nmo-guard/objective-manager.sp"
#include "nmrih-record/objective.sp"
#include "nmrih-record/player.sp"
#include "nmrih-record/printer.sp"
#include "nmrih-record/menu.sp"

#if      defined INCLUDE_MANAGER
#include "nmrih-record/manager.sp"
#endif


Handle   global_timer;              // 全局通用 | 定时循环调用
float    cv_global_timer_interval;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    LoadNative_Player();
    LoadOffset_Player();
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("nmrih-record.phrases");

    ConVar convar;
    (convar = CreateConVar("sm_nr_global_timer_interval", "60.0", "全局定时器时间间隔(秒) | 不建议修改 | 目前用于维护数据库连接与更新玩家游戏时长")).AddChangeHook(OnGlobalConVarChange);
    cv_global_timer_interval = convar.FloatValue;
    CreateConVar("sm_nr_version", NR_VERSION);

    // dbi
    nr_dbi = new NRDbi();
    LoadConVar_DBI();
    nr_dbi.connectAsyncDatabase(cv_dbi_conf_name);

    // map
    nr_map = new NRMap();

    // Round
    nr_round = new NRRound();
    LoadHook_Round();

    // Objective
    nr_objective = new NRObjective();
    LoadGamedata();
    LoadHook_Objective();

    // Player
    for(int client=1; client<=MaxClients; ++client)
    {
        nr_player_data[client] = new NRPlayerData(client);
    }
    nr_player_func = new NRPlayerFunc();
    LoadConVar_Player();
    LoadHook_Player();

    // Printer
    nr_printer = new NRPrinter();
    protect_printer_extracted_rank = new ArrayList();
    LoadConVar_Printer();

    // menu
    LoadConVar_Menu();
    LoadCmd_Menu();

    if( LibraryExists("clientprefs") )
    {
        LoadClientPrefs_Menu();
    }

#if defined INCLUDE_MANAGER
    nr_manager = new NRManager();
    LoadHook_Manager();
#endif

    AutoExecConfig(true, "nmrih-record");
}

void OnGlobalConVarChange(ConVar convar, char[] old_value, char[] new_value)
{
    if( convar == INVALID_HANDLE )
    {
        return ;
    }

    char convar_name[64];
    convar.GetName(convar_name, sizeof(convar_name));
    if( strcmp(convar_name, "sm_nr_global_timer_interval") == 0 )
    {
        cv_global_timer_interval = convar.FloatValue;
        if( global_timer != INVALID_HANDLE )
        {
            delete global_timer;
        }
        global_timer = CreateTimer(cv_global_timer_interval, Timer_global, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void OnMapStart()
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )          // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    char sql_str[128];
    nr_map.insNewMap_sqlStr(sql_str, sizeof(sql_str));              // 新增地图记录
    nr_map.map_id = nr_dbi.syncExeStrSQL_GetId(sql_str);

    if( global_timer == INVALID_HANDLE )
    {
        global_timer = CreateTimer(cv_global_timer_interval, Timer_global, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }

    // 查询并缓存撤离数据
    if( cv_menu_top_enabled )
    {
        Menu_GetAllExtractedData();
    }
}

Action Timer_global(Handle timer, any data)
{
    static int now_time;
    static int last_time_dbi, last_time_player;

    now_time = GetTime();

    // dbi
    if( nr_dbi.keep_alive && now_time - last_time_dbi >= RoundToFloor(nr_dbi.keep_alive_interval))
    {
        last_time_dbi = now_time;
        GloabalTimer_Dbi();
    }

    // player
    if( now_time - last_time_player >= RoundToFloor(nr_player_func.play_time_interval) )
    {
        last_time_player = now_time;
        for(int client=1; client<=MaxClients; ++client)
        {
            if( IsClientInGame(client) )
            {
                nr_player_data[client].play_time = GetClientTime(client);
            }
        }
    }
    return Plugin_Continue;
}

public void OnMapEnd()
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )          // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    char sql_str[128];

    if( nr_round.round_id > 0 && nr_round.practice == false )       // 更新 回合 结束
    {
        nr_round.updRoundEnd_sqlStr(sql_str, sizeof(sql_str));
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }

    nr_map.updMapEnd_sqlStr(sql_str, sizeof(sql_str));              // 更新 地图 结束
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
}

public void OnPluginEnd()
{
    if( nr_dbi.db != null )
    {
        delete nr_dbi.db;
    }
}



// * Round
// 练习时间开始, 更新 practice_ending_time (并非结束, 进入正式计时是 nmrih_round_begin)
void On_nmrih_practice_ending(Event event, const char[] name, bool dontBroadcast)
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )          // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    char sql_str[160];

    if( nr_round.round_id > 0 )
    {
        nr_round.updRoundEnd_sqlStr(sql_str, sizeof(sql_str));      // 更新回合 end_time
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }

    nr_round.practice = true;                                       // 记录回合
    nr_round.insNewRound_sqlStr(sql_str, sizeof(sql_str), -1, "practice");
    nr_round.round_id = nr_dbi.syncExeStrSQL_GetId(sql_str);

    // strcopy(protect_obj_chain, MAX_MD5_LEN, NULL_STRING);
    strcopy(protect_obj_chain_md5, MAX_MD5_LEN, NULL_STRING);
}

// 地图重置 (练习时间结束也会触发此事件. 用于标记回合结束, 记录新回合)
void On_nmrih_reset_map(Event event, const char[] name, bool dontBroadcast)
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )          // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    float game_time = GetEngineTime();
    char sql_str[700];

    // 更新回合 end_time    // * 256
    nr_round.updRoundEnd_sqlStr(sql_str, sizeof(sql_str));
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

    // 先累加, 然后清空玩家数据
    for(int client=1; client<=MaxClients; ++client)
    {
        if( IsClientInGame(client) && IsPlayerAlive(client) && nr_player_data[client].steam_id != 0 &&  nr_player_data[client].aready_submit_data == false )
        {
            nr_player_func.insNewRoundData_sqlStr(sql_str, sizeof(sql_str), client, game_time, "restart");
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

            nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), client, 0, 0);
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
        }
        nr_player_data[client].cleanup_stats();
    }

    // 刷新任务链
    UpdateObiChain();
    protect_printer_extracted_rank.Clear();

    // 记录回合
    nr_round.practice = false;
    if( nr_map.map_type == MAP_TYPE_NMO )
    {
        // 获取当前回合的任务链信息 (NMS 也会触发, 但此时可能获取不到 overlord_wave_controller)
        nr_objective.GetObjectiveChainIDString(protect_obj_chain, MAX_OBJ_CHAIN_STR_LEN, NULL_STRING);
        nr_objective.GetObjectiveChainMD5(protect_obj_chain, protect_obj_chain_md5, MAX_MD5_LEN);

        nr_round.insNewRound_sqlStr(sql_str, sizeof(sql_str), nr_objective.obj_chain_len, protect_obj_chain_md5);
        nr_round.round_id = nr_dbi.syncExeStrSQL_GetId(sql_str);

        if( nr_printer.show_obj_chain_md5 )                         // [提示] 路线ID: {2}
        {
            nr_printer.PtintObjChainMD5(protect_obj_chain_md5);
        }
    }
    else if( nr_map.map_type == MAP_TYPE_NMS )
    {
        // strcopy(protect_obj_chain, MAX_MD5_LEN, protect_map_map_name);
        strcopy(protect_obj_chain_md5, MAX_MD5_LEN, protect_map_map_name);

        nr_round.insNewRound_sqlStr(sql_str, sizeof(sql_str), nr_objective.wave_end, protect_map_map_name);
        nr_round.round_id = nr_dbi.syncExeStrSQL_GetId(sql_str);

        if( nr_printer.show_wave_max )                              // [提示] 当前地图: {2} | wave数: {3}
        {
            nr_printer.PrintObjWaveMax(nr_objective.wave_end);
        }
    }

    // 查询并缓存撤离数据
    if( cv_menu_top_enabled )
    {
        Menu_GetAllExtractedData();
    }

    if( nr_printer.show_extraction_time )
    {
        nr_printer.PrintExtractedInfo();
    }
}

// round 开始后触发 (可用于判断正式计时开始)
void On_nmrih_round_begin(Event event, const char[] name, bool dontBroadcast)
{
    char sql_str[128];
    nr_round.updRoundBegin_sqlStr(sql_str, sizeof(sql_str));
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
}

// 与 nmrih_round_begin 类似, 但触发在其之后, 用于 NMS 地图
void On_wave_system_begin(Event event, const char[] name, bool dontBroadcast)
{
    char sql_str[128];
    nr_round.updRoundBegin_sqlStr(sql_str, sizeof(sql_str));
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
}



// * Objective
// 新 任务
Action UserMsg_Objective(UserMsg msg, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
    // 获取任务信息
    char text[MAX_OBJNOTIFY_LEN];
    bf.ReadString(text, sizeof(text));

    // 记录任务
    char sql_str[384];
    nr_objective.insNewObjective_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), text, -1);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

    if( nr_printer.show_obj_start )                                 // [提示] 任务ID: {2} ({3}/{4}) | 信息: {5}
    {
        DataPack data = new DataPack();
        data.WriteString(text);
        RequestFrame(PrintObjStart, data);
    }
    return Plugin_Continue;
}

// 新 wave
void On_new_wave(Event event, const char[] name, bool dontBroadcast)
{
    bool resupply = event.GetBool("resupply");

    // 记录任务 (new_wave)
    char sql_str[256];
    nr_objective.insNewObjective_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), NULL_STRING, resupply);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

    // Wave_end == 1 - [提示] wave: {2} / {3} (空投)
    // Wave_end == 0 - [提示] wave: {2} (空投)
    if( nr_printer.show_wave_start )                                // TODO: 优化, 不用每个 wave 都重新获取 wave_end
    {
        nr_printer.PrintNewWave(nr_objective.wave_serial, nr_objective.wave_end, resupply);
    }
}

// 撤离开始
void On_extraction_begin(Event event, const char[] name, bool dontBroadcast)
{
    // 更新回合 撤离开始时间
    char sql_str[256];
    nr_round.updRoundExtractionBegin_sqlStr(sql_str, sizeof(sql_str));
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

    // 记录任务 撤离开始
    if( nr_map.map_type == MAP_TYPE_NMO )
    {
        nr_objective.insNewObjective_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), "extraction_begin", -1);
    }
    else if( nr_map.map_type == MAP_TYPE_NMS )
    {
        nr_objective.insNewObjective_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), "extraction_begin", 0);
    }
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

    // 最后一个 任务/wave 完成 输出开始撤离
    // NMO - [提示] 任务ID: {2} ({3}/{4}) | 信息: 救援已到, 快润!
    // NMS - [提示] 信息: 救援已到, 快润!
    if( nr_printer.show_extraction_begin )
    {
        nr_printer.PrintExtractionBegin( nr_round.extraction_begin_time - nr_round.begin_time );
    }
}



// * Player
// 玩家加入服务器 (可能比 round start 更早 | OnClientAuthorized 可能比这触发更早)
public void OnClientPutInServer(int client)
{
    nr_player_data[client].cleanup_stats();                         // 保证玩家统计数据已清空
    nr_player_data[client].put_in_time = GetTime();
    nr_player_data[client].prefs = GetClientPrefsIntValue(client);
    nr_player_data[client].steam_id = GetSteamAccountID(client);    // 避免 OnClientAuthorized 可能触发更早产生的问题

    SDKHook(client, SDKHook_OnTakeDamage, On_player_TakeDamage);

    DataPack data = new DataPack();                                 // 记录玩家来源、玩家名字 | 输出玩家来源
    CreateDataTimer(nr_player_func.delay_show_play_time, Timer_OnClientPutInServer, data, TIMER_DATA_HNDL_CLOSE);

    data.WriteCell(client);

#if defined INCLUDE_MANAGER
    char name[MAX_NAME_LENGTH],             name_escape[MAX_NAME_LENGTH];
    char ip[32],                            ip_escape[32];
    char country[32],                       country_escape[32];
    char continent[32],                     continent_escape[32];
    char region[32],                        region_escape[32];
    char city[32],                          city_escape[32];

    GetClientName(client,   name,           MAX_NAME_LENGTH);
    GetClientIP(client,     ip,             sizeof(ip));
    GeoipCountryEx(ip,      country,        sizeof(country),        LANG_SERVER);
    GeoipContinent(ip,      continent,      sizeof(continent),      LANG_SERVER);
    GeoipRegion(ip,         region,         sizeof(region),         LANG_SERVER);
    GeoipCity(ip,           city,           sizeof(city),           LANG_SERVER);

    nr_dbi.db.Escape(       name,           name_escape,            MAX_NAME_LENGTH);
    nr_dbi.db.Escape(       ip,             ip_escape,              sizeof(ip_escape));
    nr_dbi.db.Escape(       country,        country_escape,         sizeof(country_escape));
    nr_dbi.db.Escape(       continent,      continent_escape,       sizeof(continent_escape));
    nr_dbi.db.Escape(       region,         region_escape,          sizeof(region_escape));
    nr_dbi.db.Escape(       city,           city_escape,            sizeof(city_escape));

    data.WriteCell(GetTime());
    data.WriteCell(nr_player_data[client].steam_id);
    data.WriteString(name_escape);
    data.WriteString(ip_escape);
    data.WriteString(country_escape);
    data.WriteString(region_escape);
    data.WriteString(city_escape);
    data.WriteString(city_escape);
#endif
}

Action Timer_OnClientPutInServer(Handle timer, DataPack data)
{
    data.Reset();
    int client = data.ReadCell();

#if defined INCLUDE_MANAGER
    int create_time = data.ReadCell();
    int steam_id = data.ReadCell();
    if( IsClientInGame(client) )
    {
        steam_id = GetSteamAccountID(client);
    }

    char sql_str[384],      name[MAX_NAME_LENGTH];
    char ip[32],            country[32],    continent[32],          region[32],     city[32];
    data.ReadString(        name,           MAX_NAME_LENGTH);
    data.ReadString(        ip,             sizeof(ip));
    data.ReadString(        country,        sizeof(country));
    data.ReadString(        continent,      sizeof(continent));
    data.ReadString(        region,         sizeof(region));
    data.ReadString(        city,           sizeof(city));

    nr_manager.insNewPlayerPutIn_sqlStr(sql_str, sizeof(sql_str), steam_id, name, ip, country, continent, region, city, create_time);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);   // 记录玩家来源
#endif

    if( IsClientInGame(client) && nr_player_data[client].steam_id != 0 && nr_printer.show_play_time )
    {
        nr_printer.PrintWelcome(client);
    }
    return Plugin_Stop;
}

// 玩家获得授权 (在这之前可能获取不到 steam_id)
public void OnClientAuthorized(int client, const char[] auth)
{
    nr_player_data[client].steam_id = GetSteamAccountID(client);

    char sql_str[256];                                              // 记录玩家 统计信息 (可能比 round start 更早, 但此处不涉及 round_id)
    char name[MAX_NAME_LENGTH],             name_escape[MAX_NAME_LENGTH];

    nr_player_func.insNewPlayerStats_sqlStr(sql_str, sizeof(sql_str), client);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

    GetClientName(client,   name,           MAX_NAME_LENGTH);       // 记录玩家 steam_id 与名字的映射 (修改名字后会进行更新)
    nr_dbi.db.Escape(       name,           name_escape,            MAX_NAME_LENGTH);

    nr_player_func.insNewPlayerName_sqlStr(sql_str, sizeof(sql_str), nr_player_data[client].steam_id, name_escape);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);
}

// 触发 玩家复活
void On_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    nr_player_data[client].cleanup_stats();                         // 保证玩家统计数据已清空
    nr_player_data[client].aready_submit_data = false;
    nr_player_data[client].spawn_time = GetEngineTime();
}

// 玩家受伤 (凶手可能是自己, 也可能不是玩家 | 触发与伤害完成之前 )
Action On_player_TakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if( ! IsPlayerAlive(victim) )
    {
        return Plugin_Continue;
    }

    int victim_hp = GetClientHealth(victim);  // 获取到的是减去伤害前的拥有生命值
    if( victim_hp <= 0 )
    {
        return Plugin_Continue;
    }

    int victim_id = GetSteamAccountID(victim);
    int attacker_id, real_dmg;
    char weapon_name[MAX_WEAPON_LEN];

    if( FloatCompare(damage, float(victim_hp)) == 1 )
    {
        real_dmg = victim_hp;
    }
    else
    {
        real_dmg = RoundToFloor(damage);
        if( real_dmg <= 0 )
        {
            real_dmg = 1;
        }
    }

    nr_player_data[victim].hurt_cnt_total += 1;

    if( victim == attacker )                                        // 自己对自己造成伤害
    {
        attacker_id = victim_id;
        nr_player_data[victim].hurt_dmg_total += real_dmg;
        if( victim == inflictor )                                   // 武器也是自己
        {
            if( GetEntData(victim, nr_player_func.offset_bleedingOut, 1) && damagetype == DMG_RADIATION && FloatCompare(damage, nr_player_func.bleedout_dmg) == 0 ) // 流血
            {
                nr_player_data[victim].hurt_cnt_bleed += 1;
                nr_player_data[victim].hurt_dmg_bleed += real_dmg;
                strcopy(weapon_name, MAX_WEAPON_LEN, "_bleed");
            }
            else if( RunEntVScriptBool(victim, "IsInfected()") && damagetype == DMG_GENERIC && FloatCompare(damage, 100.0) == 0 ) // 感染
            {
                strcopy(weapon_name, MAX_WEAPON_LEN, "_infected");
            }
            else                                                    // ! 未知
            {
                strcopy(weapon_name, MAX_WEAPON_LEN, "_self");
            }
        }
        else                                                        // 其他武器对自己造成伤害 (投掷物、油桶等)
        {
            GetEntityClassname(inflictor, weapon_name, MAX_WEAPON_LEN);
        }
    }
    else if( attacker <= MaxClients && attacker > 0 )               // 被其他玩家攻击
    {
        attacker_id = nr_player_data[attacker].steam_id;

        real_dmg = RoundToFloor(damage * nr_player_func.ff_factor);
        if( real_dmg > victim_hp )
        {
            real_dmg = victim_hp;
        }
        else if( real_dmg < 1 )
        {
            real_dmg = 1;
        }

        nr_player_data[victim].hurt_cnt_player += 1;
        nr_player_data[victim].hurt_dmg_player += real_dmg;
        nr_player_data[victim].hurt_dmg_total += real_dmg;
        nr_player_data[attacker].inflict_cnt_player += 1;
        nr_player_data[attacker].inflict_dmg_player += real_dmg;
        nr_player_data[attacker].inflict_dmg_total += real_dmg;

        GetEntityClassname(inflictor, weapon_name, MAX_WEAPON_LEN);
    }
    else                                                            // 被 NPC、其他 攻击
    {
        attacker_id = attacker;                                     // 不会超过 2048 (部分游戏可能是 4096)
        nr_player_data[victim].hurt_dmg_total += real_dmg;

        GetEntityClassname(inflictor, weapon_name, MAX_WEAPON_LEN);

        if( ! strcmp(weapon_name, "npc_nmrih_shamblerzombie") )
        {
            nr_player_data[victim].hurt_cnt_shambler += 1;
            nr_player_data[victim].hurt_dmg_shambler += real_dmg;
        }
        else if( ! strcmp(weapon_name, "npc_nmrih_runnerzombie") )
        {
            nr_player_data[victim].hurt_cnt_runner += 1;
            nr_player_data[victim].hurt_dmg_runner += real_dmg;
        }
        else if( ! strcmp(weapon_name, "npc_nmrih_kidzombie") )
        {
            nr_player_data[victim].hurt_cnt_kid += 1;
            nr_player_data[victim].hurt_dmg_kid += real_dmg;
        }
        else if( ! strcmp(weapon_name, "npc_nmrih_turnedzombie") )
        {
            nr_player_data[victim].hurt_cnt_turned += 1;
            nr_player_data[victim].hurt_dmg_turned += real_dmg;
        }
    }

#if defined INCLUDE_MANAGER
    char sql_str[160];
    nr_manager.insNewPlayerHurt_sqlStr(sql_str, sizeof(sql_str), victim_id, attacker_id, weapon_name, real_dmg, damagetype);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
#endif

    // char atc_name[32];
    // GetEdictClassname(attacker, atc_name, 32);
    // PrintToChatAll("pp | vic:%d | atc: %d | atc:%s | wap:%s | dmg: %f | rdmg: %d", victim, attacker, atc_name, weapon_name, damage, real_dmg);
    // LogMessage("pl | vic:%d | atc: %d | atc: %s | wap:%s | dmg: %f | rdmg: %d", victim, attacker, atc_name, weapon_name, damage, real_dmg);

    return Plugin_Continue;
}

// 监听丧尸被攻击事件
public void OnEntityCreated(int entity, const char[] classname)
{
    if( StrContains(classname, "npc_nmrih_") != -1 && StrContains(classname, "zombie") != -1 )
    {
        SDKHook(entity, SDKHook_OnTakeDamage, On_zombie_TakeDamage);
    }
}

// 回调 丧尸被攻击
Action On_zombie_TakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if( victim > MaxClients && attacker <= MaxClients && attacker > 0 )
    {
        int victim_hp = GetEntProp(victim, Prop_Data, "m_iHealth", 1);
        if( victim_hp <= 0 )
        {
            return Plugin_Continue;
        }

        char victim_classname[32];
        GetEntityClassname(victim, victim_classname, sizeof(victim_classname));

        int real_dmg;
        if( FloatCompare(damage, float(victim_hp)) == 1 )
        {
            real_dmg = victim_hp;
        }
        else
        {
            real_dmg = RoundToFloor(damage);
            if( real_dmg <= 0 )
            {
                real_dmg = 1;
            }
        }
        nr_player_data[attacker].inflict_dmg_total += real_dmg;

        if( ! strcmp(victim_classname, "npc_nmrih_shamblerzombie") )
        {
            nr_player_data[attacker].inflict_dmg_shambler += real_dmg;
        }
        else if( ! strcmp(victim_classname, "npc_nmrih_runnerzombie") )
        {
            nr_player_data[attacker].inflict_dmg_runner += real_dmg;
        }
        else if( ! strcmp(victim_classname, "npc_nmrih_kidzombie") )
        {
            nr_player_data[attacker].inflict_dmg_kid += real_dmg;
        }
        else if( ! strcmp(victim_classname, "npc_nmrih_turnedzombie") )
        {
            nr_player_data[attacker].inflict_dmg_turned += real_dmg;
        }

        if( IsValidEntity(inflictor) )
        {
            char inflictor_classname[32];
            GetEntityClassname(inflictor, inflictor_classname, sizeof(inflictor_classname));
            if( StrContains(inflictor_classname, "me_") != -1 || StrContains(inflictor_classname, "tool_") != -1 )
            {
                nr_player_data[attacker].inflict_dmg_melee += real_dmg;
            }
            else if( StrContains(inflictor_classname, "fa_") != -1 || StrContains(inflictor_classname, "bow_") != -1 )
            {
                nr_player_data[attacker].inflict_dmg_firearm += real_dmg;
            }
            // | exp_grenade | exp_tnt | grenade_projectile | tnt_projectile |
            else if( StrContains(inflictor_classname, "grenade") != -1 || StrContains(inflictor_classname, "tnt") != -1 )
            {
                nr_player_data[attacker].inflict_dmg_explode += real_dmg;
            }
            // | entityflame | exp_molotov | molotov_projectile |
            else if( StrContains(inflictor_classname, "flame") != -1 || StrContains(inflictor_classname, "molotov") != -1 )
            {
                nr_player_data[attacker].inflict_dmg_flame += real_dmg;
            }
        }

        // char vic_name[32], weapon_name[32];
        // GetEntityClassname(victim, vic_name, sizeof(vic_name));
        // GetEntityClassname(inflictor, weapon_name, sizeof(weapon_name));
        // PrintToChatAll("zp | vic:%s | vic: %d | atc:%d | wap:%s | dmg: %f | rdmg: %d", vic_name, victim, attacker, weapon_name, damage, real_dmg);
        // LogMessage("zl | vic:%s | vic: %d | atc:%d | wap:%s | dmg: %f | rdmg: %d", vic_name, victim, attacker, weapon_name, damage, real_dmg);

    }
    return Plugin_Continue;
}

// 触发 击杀 (任何玩家击杀都会触发此事件, 包括爆头、燃烧)
void On_npc_killed(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("killeridx");
    if( client <= MaxClients && client > 0 )
    {
        nr_player_data[client].kill_cnt_total += 1;
        int npc_type = event.GetInt("npctype");
        switch( npc_type )
        {
            case 1  : nr_player_data[client].kill_cnt_shambler += 1;
            case 2  : nr_player_data[client].kill_cnt_runner += 1;
            case 3  : nr_player_data[client].kill_cnt_kid += 1;
            case 4  : nr_player_data[client].kill_cnt_turned += 1;
        }

        int weapin_id = event.GetInt("weaponid");
        if( 23 <= weapin_id <= 42 || weapin_id == 48 || 64 <= weapin_id <= 65 )
        {
            nr_player_data[client].kill_cnt_melee += 1;
        }
        else if( 1 <= weapin_id <= 22 || 65 <= weapin_id <= 67 )
        {
            nr_player_data[client].kill_cnt_firearm += 1;
        }
        else if( 49 == weapin_id || weapin_id == 51 )
        {
            nr_player_data[client].kill_cnt_explode += 1;
        }
    }
}

void On_zombie_killed_by_fire(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("igniter_id");
    if( client <= MaxClients && client > 0 )
    {
        nr_player_data[client].kill_cnt_flame += 1;
    }
}

// 触发 玩家爆头击杀丧尸
void On_zombie_head_split(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("player_id");
    nr_player_data[client].kill_cnt_headSplit += 1;
}

// 触发 分享物品
public void On_item_given(Event event, char[] name, bool dontBroadcast)
{
    int receiver = GetClientOfUserId( event.GetInt("receiver") );
    int giver    = GetClientOfUserId( event.GetInt("userid") );

    char classname[MAX_WEAPON_LEN];
    event.GetString("classname", classname, MAX_WEAPON_LEN);

    if( StrContains(classname, "bandages") != -1 )
    {
        nr_player_data[receiver].share_cnt_bandages += 1;
        nr_player_data[giver].receive_cnt_bandages += 1;
    }
    else if( StrContains(classname, "first_aid") != -1 )
    {
        nr_player_data[receiver].share_cnt_first_aid += 1;
        nr_player_data[giver].receive_cnt_first_aid += 1;
    }
    else if( StrContains(classname, "pills") != -1 )
    {
        nr_player_data[receiver].share_cnt_pills += 1;
        nr_player_data[giver].receive_cnt_pills += 1;
    }
    else if( StrContains(classname, "gene_therapy") != -1 )
    {
        nr_player_data[receiver].share_cnt_gene_therapy += 1;
        nr_player_data[giver].receive_cnt_gene_therapy += 1;
    }
}

// 触发 玩家使用药丸
public void On_pills_taken(Event event, char[] name, bool dontBroadcast)
{
    int client = event.GetInt("player_id");
    nr_player_data[client].taken_cnt_pills += 1;
}

// 触发 玩家使用疫苗
public void On_vaccine_taken(Event event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    nr_player_data[client].taken_cnt_gene_therapy += 1;

    if( event.GetBool("effect") )
    {
        nr_player_data[client].effect_cnt_gene_therapy += 1;
    }
}

// 触发 玩家撤离
void On_player_extracted(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("player_id");

    if( nr_player_data[client].steam_id != 0 )
    {
        if( nr_player_data[client].aready_submit_data == false )
        {
            float engine_time = GetEngineTime();
            nr_player_data[client].aready_submit_data = true;

            char sql_str[700];
            // 记录回合玩家数据
            nr_player_func.insNewRoundData_sqlStr(sql_str, sizeof(sql_str), client, engine_time, "extracted");
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

            // 累加统计
            nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), client, 0, 1);
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

            // 输出撤离信息
            // [提示] {name} 撤离成功! 用时: {minute}:{seconds} 击杀: {int}
            if( nr_printer.show_player_extraction )
            {
                nr_printer.PrintPlayerExtraction(client, engine_time);
            }

            nr_player_data[client].cleanup_stats();
        }
    }
    else    // [提示] {name} 的 steam id 为 0, 无法记录
    {
        LogMessage("On_player_extracted | client: %d | name: %N | steam: %d | aready: %d |", client, client, nr_player_data[client].steam_id, nr_player_data[client].aready_submit_data) ;
    }
}

// 触发 西瓜救援成功
void On_watermelon_rescue(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if( nr_player_data[client].steam_id != 0 )
    {
        // 记录任务 西瓜救援成功（* 记录在任务表中）
        char sql_str[96];
        nr_player_func.insNewWatermelonRescue_sqlStr(sql_str, sizeof(sql_str), client);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }
    else    // [提示] {name} 的 steam id 为 0, 无法记录
    {
        LogMessage("On_watermelon_rescue | client: %d | name: %N | steam: %d | aready: %d |", client, client, nr_player_data[client].steam_id, nr_player_data[client].aready_submit_data) ;
    }

    // 输出 西瓜救援成功
    // [提示] Name 拯救了西瓜!
    if( nr_printer.show_watermelon_rescue )
    {
        nr_printer.PrintWatermelonRescue(client);
    }
}

// 触发 玩家死亡
public void On_player_death(Event event, char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId( event.GetInt("userid") );
    if( nr_player_data[victim].steam_id != 0 )
    {
        if( nr_player_data[victim].aready_submit_data == false )
        {
            float game_time = GetEngineTime();
            nr_player_data[victim].aready_submit_data = true;

            int npc_type = event.GetInt("npctype");
            int attacker = GetClientOfUserId( event.GetInt("attacker") );

            // 死于玩家之手
            if( npc_type == 0 && victim <= MaxClients && victim > 0 && victim != attacker && attacker <= MaxClients && attacker > 0 )
            {
                nr_player_data[attacker].kill_cnt_player += 1;
            }

            char sql_str[700];
            // 记录回合玩家数据
            nr_player_func.insNewRoundData_sqlStr(sql_str, sizeof(sql_str), victim, game_time, "death");
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

            // 累加统计
            nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), victim, 0, 0);
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

            nr_player_data[victim].cleanup_stats();
        }
    }
    else    // [提示] {name} 的 steam id 为 0, 无法记录
    {
        LogMessage("On_player_death | client: %d | name: %N | steam: %d | aready: %d |", victim, victim, nr_player_data[victim].steam_id, nr_player_data[victim].aready_submit_data) ;
    }
}

// 触发 玩家离开 (换图也会触发, 而 OnClientDisconnect 在换图时不会触发)
public void On_player_leave(Event event, char[] name, bool dontBroadcast)
{
    int client = event.GetInt("index");
    if( nr_player_data[client].steam_id != 0 )
    {
        if( nr_player_data[client].aready_submit_data == false )
        {
            float game_time = GetEngineTime();
            nr_player_data[client].aready_submit_data = true;

            char sql_str[700];

            // 记录回合玩家数据
            nr_player_func.insNewRoundData_sqlStr(sql_str, sizeof(sql_str), client, game_time, "leave");
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

            // 累加统计
            nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), client, 0, 0);
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

            // 全部重置玩家数据
            nr_player_data[client].cleanup_stats();
        }
    }
    else    // [提示] {name} 的 steam id 为 0, 无法记录
    {
        LogMessage("On_player_leave | client: %d | name: %N | steam: %d | aready: %d |", client, client, nr_player_data[client].steam_id, nr_player_data[client].aready_submit_data) ;
    }
}

// 玩家退出服务器
void On_player_disconnect(Event event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client <= MaxClients && client > 0 )                        // map 换图时存在 client index = 0 的 bug
    {
        int play_time;
        if( IsClientInGame(client) )
        {
            play_time = RoundToCeil( GetClientTime(client) );
        }
        else if( FloatCompare(nr_player_data[client].play_time, 0.0) >= 0 )
        {
            // play_time = GetTime() - nr_player_data[client].put_in_time;
            play_time = RoundToCeil( nr_player_data[client].play_time );
            nr_player_data[client].put_in_time = 0;
            nr_player_data[client].play_time = 0.0;
        }
        else
        {
            return ;
        }

        char sql_str[700];
        if( nr_player_data[client].steam_id != 0 )
        {
            // 累加统计
            nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), client, play_time, 0);
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
        }

#if defined INCLUDE_MANAGER
        char reason[MAX_NAME_LENGTH],   reason_escape[MAX_NAME_LENGTH];
        char networkid[32],             networkid_escape[32];
        event.GetString("reason",       reason,             sizeof(reason),         NULL_STRING);
        event.GetString("networkid",    networkid,          sizeof(networkid),      NULL_STRING);

        nr_dbi.db.Escape(reason,        reason_escape,      sizeof(reason_escape));
        nr_dbi.db.Escape(networkid,     networkid_escape,   sizeof(networkid_escape));

        nr_manager.insNewPlayerDisconnect_sqlStr(sql_str,   sizeof(sql_str), client, reason_escape, networkid_escape, play_time);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
#endif
    }
}

