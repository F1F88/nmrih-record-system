#pragma newdecls required
#pragma semicolon 1


#define     _DEBUG_player_hurt
#define     _DEBUG_zombie_hurt
// #define     _DEBUG_npc_killed
// #define     _DEBUG_zombie_head_split
// #define     _DEBUG_player_death
// #define     _DEBUG_player_stats


char     json_path[64];                         // log-map-(int)    在新增 map_id 完成后更新

public void debug_player_stats(const char[] sql_str)
{
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",         "nmrih_reset_map");
    json_obj.SetString("sql",           sql_str);
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}

public void debug_player_hurt(const int victim, const int real_dmg)
{
    int steam_id = nr_player_data[victim].steam_id;
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",         "player_hurt");
    json_obj.SetInt("mapID",            nr_map.map_id);
    json_obj.SetInt("roundID",          nr_round.round_id);
    json_obj.SetInt("timestamp",        GetTime());
    json_obj.SetFloat("EngineTime",     GetEngineTime());
    json_obj.SetInt("steamID",          steam_id);
    // json_obj.SetInt("zombie_hp",    zombie_hp);
    json_obj.SetInt("damage",           real_dmg);
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}

public void debug_zombie_hurt(const int attacker, const int real_dmg)
{
    int steam_id = nr_player_data[attacker].steam_id;
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",         "zombie_hurt");
    json_obj.SetInt("mapID",            nr_map.map_id);
    json_obj.SetInt("roundID",          nr_round.round_id);
    json_obj.SetInt("timestamp",        GetTime());
    json_obj.SetFloat("EngineTime",     GetEngineTime());
    json_obj.SetInt("steamID",          steam_id);
    // json_obj.SetInt("zombie_hp",    zombie_hp);
    json_obj.SetInt("damage",           real_dmg);
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}

public void debug_npc_killed(const int steam_id, const bool isturned, int weapon_id, ZOMBIE_TYPE npc_type)
{
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",       "npc_killed");
    json_obj.SetInt("mapID",          nr_map.map_id);
    json_obj.SetInt("roundID",        nr_round.round_id);
    json_obj.SetInt("timestamp",      GetTime());
    json_obj.SetFloat("EngineTime",   GetEngineTime());
    // json_obj.SetInt("entidx",         entidx);
    // json_obj.SetInt("client",         client);
    json_obj.SetInt("steamID",        steam_id);
    json_obj.SetBool("isturned",      isturned);
    json_obj.SetInt("weaponid",       weapon_id);
    json_obj.SetInt("npctype",        view_as<int>(npc_type));
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}

public void debug_zombie_head_split(const int steam_id)
{
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",       "zombie_head_split");
    json_obj.SetInt("mapID",          nr_map.map_id);
    json_obj.SetInt("roundID",        nr_round.round_id);
    json_obj.SetInt("timestamp",      GetTime());
    json_obj.SetFloat("EngineTime",   GetEngineTime());
    // json_obj.SetInt("client",         client);
    json_obj.SetInt("steamID",        steam_id);
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}

public void debug_player_death(const int victim_id, const int attacker_id, ZOMBIE_TYPE npc_type, const char[] weapon)
{
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",       "player_death");
    json_obj.SetInt("mapID",          nr_map.map_id);
    json_obj.SetInt("roundID",        nr_round.round_id);
    json_obj.SetInt("timestamp",      GetTime());
    json_obj.SetFloat("EngineTime",   GetEngineTime());
    json_obj.SetInt("steamID",        attacker_id);
    json_obj.SetInt("victimID",       victim_id);
    json_obj.SetInt("attackerID",     attacker_id);
    json_obj.SetInt("npctype",        view_as<int>(npc_type));
    json_obj.SetString("weapon",      weapon);
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}


public void debug_player_extracted(const char[] sql_str)
{
    JSON_Object json_obj = new JSON_Object();
    json_obj.SetString("Event",       "player_extracted");
    json_obj.SetString("sql_str",      sql_str);
    json_obj.WriteToFile(json_path);
    json_cleanup_and_delete(json_obj);
}
