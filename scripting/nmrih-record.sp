// Todo: 在地图、回合信息记录失败时停止记录
// Todo: 补充撤离时的用时排名
// Todo  补充使用绷带和医疗包事件及记录字段
// Todo: 完善 Late 时的加载信息
// Note: In my tests, I found that StrContains performs well, even slightly better than strcmp. But be careful not to set caseSensitive to false

#pragma newdecls required
#pragma semicolon 1

#define INCLUDE_MANAGER

#include <sourcemod>
#include <geoip>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#include <smlib/crypt>

#include <dbi>
#include "nmrih-record/dbi.sp"
#include "nmrih-record/map.sp"
#include "nmrih-record/round.sp"
#include "nmo-guard/objective-manager.sp"
#include "nmrih-record/objective.sp"
#include "nmrih-record/player.sp"
#include "nmrih-record/printer.sp"


// #include "nmrih_record/menu.sp"

#if defined INCLUDE_MANAGER
#include "nmrih-record/manager.sp"
#endif


// 从磁盘加载插件后立即调用一次
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("nmrih-record.phrases");   // 加载多语言文本
    // CreateConVar("sm_nmrih_record_version", "1.0.0");

    // * dbi
    nr_dbi = new NRDbi();
    LoadDBIConVar();
    nr_dbi.connectAsyncDatabase(cv_dbi_conf_name);

    // * map
    nr_map = new NRMap();

    // * Round
    nr_round = new NRRound();
    LoadHook_Round();

    // * Objective
    nr_objective = new NRObjective();
    LoadGamedata();
    LoadHook_Objective();

    // * Player
    for(int i=1; i<=MaxClients; ++i)
    {
        nr_player_data[i] = new NRPlayerData(i);
    }
    nr_player_func = new NRPlayerFunc();
    LoadHook_Player();

    // * Printer
    nr_printer = new NRPrinter();
    protect_printer_extracted_rank = new ArrayList();
    LoadPrinterConVar();

#if defined INCLUDE_MANAGER
    // * Manager
    nr_manager = new NRManager();
    LoadHook_Manager();
#endif

    AutoExecConfig(true, "nmrih-record");       // 生成配置文件
}

public void OnMapStart()
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )  // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    // 新增地图
    char sql_str[128];
    nr_map.insNewMap_sqlStr(sql_str, sizeof(sql_str));
    nr_map.map_id = nr_dbi.syncExeStrSQL_GetId(sql_str);
}

public void OnMapEnd()
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )  // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    char sql_str[128];

    // 更新 回合 结束
    if( nr_round.round_id > 0 && nr_round.practice == false )
    {
        nr_round.updRoundEnd_sqlStr(sql_str, sizeof(sql_str));
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }

    // 更新 地图 结束
    nr_map.updMapEnd_sqlStr(sql_str, sizeof(sql_str));
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
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )  // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    char sql_str[160];
    // 更新回合 end_time
    if( nr_round.round_id > 0 )
    {
        nr_round.updRoundEnd_sqlStr(sql_str, sizeof(sql_str));
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }

    // 记录回合
    nr_round.practice = true;
    nr_round.insNewRound_sqlStr(sql_str, sizeof(sql_str), -1, "practice");
    nr_round.round_id = nr_dbi.syncExeStrSQL_GetId(sql_str);
}

// 地图重置 (练习时间结束也会触发此事件. 用于标记回合结束, 记录新回合)
void On_nmrih_reset_map(Event event, const char[] name, bool dontBroadcast)
{
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE )  // ! 疑似长时间不使用会出现 SQL 执行失败
    {
        nr_dbi.connectSyncDatabase(cv_dbi_conf_name, true);
    }

    float game_time = GetEngineTime();
    char sql_str[1280];

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

        // [提示] 路线ID: {2}
        nr_printer.PtintObjChainMD5(protect_obj_chain_md5);
    }
    else if( nr_map.map_type == MAP_TYPE_NMS )
    {
        // FormatEx(protect_obj_chain_md5, MAX_MD5_LEN, "%s", protect_map_map_name);

        nr_round.insNewRound_sqlStr(sql_str, sizeof(sql_str), nr_objective.wave_end, protect_map_map_name);
        nr_round.round_id = nr_dbi.syncExeStrSQL_GetId(sql_str);

        // [提示] 当前地图: {2} | wave数: {3}
        nr_printer.PrintObjWaveMax(nr_objective.wave_end);
    }

    nr_printer.PrintExtractedAvgTime();
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

    if( cv_printer_show_new_obj_start )     // [提示] 任务ID: {2} ({3}/{4}) | 信息: {5}
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
    nr_printer.PrintNewWave(nr_objective.wave_serial, nr_objective.wave_end, resupply);     // TODO: 优化, 不用每个 wave 都重新获取 wave_end
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
    nr_printer.PrintExtractionBegin( nr_round.extraction_begin_time - nr_round.begin_time );
}



// * Player
// 玩家加入服务器 (OnClientAuthorized 可能比这触发更早)
public void OnClientPutInServer(int client)
{
    nr_player_data[client].cleanup_stats();                         // 保证玩家统计数据已清空
    nr_player_data[client].put_in_time = GetTime();
    nr_player_data[client].steam_id = GetSteamAccountID(client);    // 避免 OnClientAuthorized 可能触发更早产生的问题

    SDKHook(client, SDKHook_OnTakeDamage, On_player_TakeDamage);

    // 记录玩家来源, 并输出玩家来源
    CreateTimer(cv_printer_delay_show_play_time, Timer_OnClientPutInServer, client, TIMER_FLAG_NO_MAPCHANGE);
}
Action Timer_OnClientPutInServer(Handle timer, int client)
{
    if( IsClientInGame(client) )
    {
#if defined INCLUDE_MANAGER
        char sql_str[200];
        nr_manager.insNewPlayerPutIn_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), client);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
#endif

        nr_printer.PrintPlayTime(client, nr_player_data[client].steam_id);
    }
    return Plugin_Stop;
}

// 玩家获得授权 (在这之前可能获取不到 steam_id)
public void OnClientAuthorized(int client, const char[] auth)
{
    nr_player_data[client].steam_id = GetSteamAccountID(client);

    // 记录玩家 统计信息、steam_id + 名字
    CreateTimer(cv_printer_delay_show_play_time, Timer_OnClientAuthorized, client, TIMER_FLAG_NO_MAPCHANGE);
}
Action Timer_OnClientAuthorized(Handle timer, int client)
{
    if( IsClientInGame(client) )
    {
        char sql_str[384];
        nr_player_func.insNewPlayerStats_sqlStr(sql_str, sizeof(sql_str), client);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str));

        nr_player_func.insNewPlayerName_sqlStr(sql_str, sizeof(sql_str), client);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }
    return Plugin_Stop;
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
    int victim_id = GetSteamAccountID(victim);
    if( ! IsPlayerAlive(victim) )
    {
        return Plugin_Continue;
    }

    int victim_hp = GetEntProp(victim, Prop_Data, "m_iHealth", 1);  // 获取到的是减去伤害前的拥有生命值
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
    nr_player_data[victim].hurt_dmg_total += real_dmg;

    if( victim == attacker )                // 自己对自己造成伤害
    {
        attacker_id = victim_id;
        if( victim == inflictor )           // 武器也是自己
        {
            if( damagetype == DMG_RADIATION && FloatCompare(damage, private_cv_bleedout_dmg) == 0 ) // 流血
            {
                nr_player_data[victim].hurt_cnt_bleed += 1;
                nr_player_data[victim].hurt_dmg_bleed += real_dmg;
                FormatEx(weapon_name, MAX_WEAPON_LEN, "_bleed");
            }
            else if( damagetype == DMG_GENERIC && FloatCompare(damage, 100.0) == 0 )                // 感染
            {
                FormatEx(weapon_name, MAX_WEAPON_LEN, "_infected");
            }
            else                            // ! 未知
            {
                FormatEx(weapon_name, MAX_WEAPON_LEN, "_self");
            }
        }
        else                                // 其他武器对自己造成伤害 (投掷物、油桶等)
        {
            GetEntityClassname(inflictor, weapon_name, MAX_WEAPON_LEN);
        }
    }
    else if( 0 < attacker <= MaxClients )   // 被其他玩家攻击
    {
        attacker_id = nr_player_data[attacker].steam_id;

        real_dmg = RoundToFloor(damage * nr_player_func.ff_factor);
        if( real_dmg > victim_hp )
        {
            real_dmg = victim_hp;
        }
        else if( real_dmg <= 0 )
        {
            real_dmg = 1;
        }

        nr_player_data[victim].hurt_cnt_player += 1;
        nr_player_data[victim].hurt_dmg_player += real_dmg;
        nr_player_data[attacker].inflict_cnt_player += 1;
        nr_player_data[attacker].inflict_dmg_player += real_dmg;
        nr_player_data[attacker].inflict_dmg_total += real_dmg;

        GetEntityClassname(inflictor, weapon_name, MAX_WEAPON_LEN);
    }
    else                                    // 被 NPC、其他 攻击
    {
        attacker_id = attacker;             // 不会超过 2048 (部分游戏可能是 4096)

        if( StrContains(weapon_name, "shamblerzombie") )
        {
            nr_player_data[victim].hurt_cnt_shambler += 1;
            nr_player_data[victim].hurt_dmg_shambler += real_dmg;
        }
        else if( StrContains(weapon_name, "runnerzombie") )
        {
            nr_player_data[victim].hurt_cnt_runner += 1;
            nr_player_data[victim].hurt_dmg_runner += real_dmg;
        }
        else if( StrContains(weapon_name, "kidzombie") )
        {
            nr_player_data[victim].hurt_cnt_kid += 1;
            nr_player_data[victim].hurt_dmg_kid += real_dmg;
        }
        else if( StrContains(weapon_name, "turnedzombie") )
        {
            nr_player_data[victim].hurt_cnt_turned += 1;
            nr_player_data[victim].hurt_dmg_turned += real_dmg;
        }
        GetEntityClassname(inflictor, weapon_name, MAX_WEAPON_LEN);
    }
#if defined INCLUDE_MANAGER
    char sql_str[200];
    nr_manager.insNewPlayerHurt_sqlStr(sql_str, sizeof(sql_str), victim_id, attacker_id, weapon_name, real_dmg, damagetype);
    nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
#endif
    return Plugin_Continue;
}

// 监听丧尸被攻击事件
public void OnEntityCreated(int entity, const char[] classname)
{
    if( StrContains(classname, "nmc_nmrih") && StrContains(classname, "zombie") )
    {
        SDKHook(entity, SDKHook_OnTakeDamage, On_zombie_TakeDamage);
    }
}
// 回调 丧尸被攻击
Action On_zombie_TakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if( 0 < attacker <= MaxClients )
    {
        int victim_hp = GetEntProp(victim, Prop_Data, "m_iHealth", 1);
        if( victim_hp <= 0 )
        {
            return Plugin_Continue;
        }

        int real_dmg;
        char victim_classname[32], inflictor_classname[32];
        GetEntityClassname(victim, victim_classname, sizeof(victim_classname));

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

        if( StrContains(victim_classname, "shamblerzombie") )
        {
            nr_player_data[attacker].inflict_dmg_shambler += real_dmg;
        }
        else if( StrContains(victim_classname, "runnerzombie") )
        {
            nr_player_data[attacker].inflict_dmg_runner += real_dmg;
        }
        else if( StrContains(victim_classname, "kidzombie") )
        {
            nr_player_data[attacker].inflict_dmg_kid += real_dmg;
        }
        else if( StrContains(victim_classname, "turnedzombie") )
        {
            nr_player_data[attacker].inflict_dmg_turned += real_dmg;
        }

        if( IsValidEntity(inflictor) )
        {
            GetEntityClassname(inflictor, inflictor_classname, sizeof(inflictor_classname));
            if( StrContains("me_", inflictor_classname) || StrContains("tool_", inflictor_classname) )
            {
                nr_player_data[attacker].inflict_dmg_melee += real_dmg;
            }
            else if( StrContains("fa_", inflictor_classname) || StrContains("bow_", inflictor_classname) )
            {
                nr_player_data[attacker].inflict_dmg_firearm += real_dmg;
            }
            // | exp_grenade | exp_tnt | grenade_projectile | tnt_projectile |
            else if( StrContains("grenade", inflictor_classname) || StrContains("tnt", inflictor_classname) )
            {
                nr_player_data[attacker].inflict_dmg_explode += real_dmg;
            }
            // | entityflame | exp_molotov | molotov_projectile |
            else if( StrContains("flame", inflictor_classname) || StrContains("molotov", inflictor_classname) )
            {
                nr_player_data[attacker].inflict_dmg_flame += real_dmg;
            }
        }
    }
    return Plugin_Continue;
}

// 触发 击杀 (任何玩家击杀都会触发此事件, 包括爆头、燃烧)
void On_npc_killed(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("killeridx");
    if( 0 < client <= MaxClients )
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
    if( 0 < client <= MaxClients )
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
    event.GetString("classname", classname, MAX_WEAPON_LEN, NULL_STRING);

    if( StrContains(classname, "bandages") )
    {
        nr_player_data[receiver].share_cnt_bandages += 1;
        nr_player_data[giver].receive_cnt_bandages += 1;
    }
    else if( StrContains(classname, "first_aid") )
    {
        nr_player_data[receiver].share_cnt_first_aid += 1;
        nr_player_data[giver].receive_cnt_first_aid += 1;
    }
    else if( StrContains(classname, "pills") )
    {
        nr_player_data[receiver].share_cnt_pills += 1;
        nr_player_data[giver].receive_cnt_pills += 1;
    }
    else if( StrContains(classname, "gene_therapy") )
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

    if( 0 < client <= MaxClients && nr_player_data[client].steam_id != 0 )
    {
        if( nr_player_data[client].aready_submit_data == false )
        {
            float game_time = GetEngineTime();
            float take_time = game_time - nr_round.begin_time;
            nr_player_data[client].aready_submit_data = true;

            char sql_str[1280];
            // 记录回合玩家数据
            nr_player_func.insNewRoundData_sqlStr(sql_str, sizeof(sql_str), client, game_time, "extracted");
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

            // 累加统计
            nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), client, 0, 1);
            nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

            // 输出撤离信息
            // [提示] {name} 撤离成功! 用时: {minute}:{seconds} 击杀: {int}
            nr_printer.PrintPlayerExtraction(client, take_time);

            nr_player_data[client].cleanup_stats();
        }
    }
    else
    {
        // [提示] {name} 的 steam id 为 0, 无法记录
        LogMessage("On_player_extracted | client: %d | name: %N | steam: %d | aready: %d |", client, client, nr_player_data[client].steam_id, nr_player_data[client].aready_submit_data);
        return ;
    }
}

// 触发 西瓜救援成功
void On_watermelon_rescue(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if( 0 < client <= MaxClients && nr_player_data[client].steam_id != 0 )
    {
        // 记录任务 西瓜救援成功（* 记录在任务表中）
        char sql_str[100];
        nr_player_func.insNewWatermelonRescue_sqlStr(sql_str, sizeof(sql_str), client);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);
    }
    else
    {
        LogMessage("On_watermelon_rescue | client: %d | name: %N | steam: %d |", client, client, nr_player_data[client].steam_id);
        return ;
    }

    // 输出 西瓜救援成功
    // [提示] Name 拯救了西瓜!
    nr_printer.PrintWatermelonRescue(client);
}

// 触发 玩家死亡
public void On_player_death(Event event, char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId( event.GetInt("userid") );
    if( nr_player_data[victim].aready_submit_data == false )
    {
        float game_time = GetEngineTime();
        nr_player_data[victim].aready_submit_data = true;

        int npc_type = event.GetInt("npctype");
        int attacker = GetClientOfUserId( event.GetInt("attacker") );

        // 死于玩家之手
        if( npc_type == 0 && 0 < victim <= MaxClients && victim != attacker )
        {
            nr_player_data[attacker].kill_cnt_player += 1;
        }

        char sql_str[1280];
        // 记录回合玩家数据
        nr_player_func.insNewRoundData_sqlStr(sql_str, sizeof(sql_str), victim, game_time, "death");
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_High);

        // 累加统计
        nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), victim, 0, 0);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

        nr_player_data[victim].cleanup_stats();
    }
}

// 触发 玩家离开 (换图也会触发, 而 OnClientDisconnect 在换图时不会触发)
public void On_player_leave(Event event, char[] name, bool dontBroadcast)
{
    int client = event.GetInt("index");
    if( 0 < client <= MaxClients && nr_player_data[client].steam_id != 0 )
    {
        if( nr_player_data[client].aready_submit_data == false )
        {
            float game_time = GetEngineTime();
            nr_player_data[client].aready_submit_data = true;

            char sql_str[1280];

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
    else
    {
        // [提示] {name} 的 steam id 为 0, 无法记录
        LogMessage("On_player_leave | client: %d | name: %N | steam: %d | aready: %d |", client, client, nr_player_data[client].steam_id, nr_player_data[client].aready_submit_data) ;
        return ;
    }
}

// 玩家退出服务器
void On_player_disconnect(Event event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( 0 < client <= MaxClients )
    {
        int play_time = GetTime() - nr_player_data[client].put_in_time;
        if( IsClientInGame(client) )
        {
            play_time = RoundToCeil( GetClientTime(client) );
        }
        else if( nr_player_data[client].put_in_time != 0 )
        {
            play_time = GetTime() - nr_player_data[client].put_in_time;
        }
        else
        {
            return ;
        }

        char sql_str[700];
        // 累加统计
        nr_player_func.updPlayerStats_sqlStr(sql_str, sizeof(sql_str), client, play_time, 0);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Normal);

#if defined INCLUDE_MANAGER
        char reason[MAX_NAME_LENGTH],                   networkid[32];
        event.GetString("reason",       reason,         sizeof(reason),         NULL_STRING);
        event.GetString("networkid",    networkid,      sizeof(networkid),      NULL_STRING);

        nr_manager.insNewPlayerDisconnect_sqlStr(nr_dbi.db, sql_str, sizeof(sql_str), client, reason, networkid, play_time);
        nr_dbi.asyncExecStrSQL(sql_str, sizeof(sql_str), DBPrio_Low);
#endif
    }
}

