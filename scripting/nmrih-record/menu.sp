#pragma newdecls required
#pragma semicolon 1


#define FIELD_NAME_MAP_NAME                         "map_name"
#define FIELD_NAME_OBJ_CHAIN_MD5                    "obj_chain_md5"
#define FIELD_NAME_ROUND_LEN                        "round_len"
#define FIELD_NAME_ROUND_BEGIN_TIME                 "round_begin_time"
#define FIELD_NAME_EXTRACTION_BEGIN_TIME            "extraction_begin_time"
#define FIELD_NAME_SPAWN_TIME                       "spawn_time"
#define FIELD_NAME_ENGINE_TIME                      "engine_time"
#define FIELD_NAME_NAME                             "name"
#define FIELD_NAME_STEAM_ID                         "steam_id"
#define FIELD_NAME_COMPLETED                        "completed"
#define FIELD_NAME_TAKE_TIME                        "take_time"


// 缓存不同语言玩家可共用的菜单
// [maps: mapList(Menu)] | [map_name: routeList(Menu)] | [map_name route: rankList(Menu)]
StringMap   protect_menu_public_menu;

bool        cv_menu_top_enabled
            , cv_menu_top10_enabled
            , cv_menu_prfs_enabled;

void LoadConVar_Menu()
{
    ConVar convar;
    (convar = CreateConVar("sm_nr_menu_top_enabled",    "0", "是否启用数据榜单菜单")).AddChangeHook(OnConVarChange_Menu);
    cv_menu_top_enabled = convar.BoolValue;
    (convar = CreateConVar("sm_nr_menu_top10_enabled",  "0", "是否启用查看当前路线最快前十名指令")).AddChangeHook(OnConVarChange_Menu);
    cv_menu_top10_enabled = convar.BoolValue;
    (convar = CreateConVar("sm_nr_menu_prefs_enabled",  "0", "是否启用玩家偏好菜单")).AddChangeHook(OnConVarChange_Menu);
    cv_menu_prfs_enabled = convar.BoolValue;
}

void OnConVarChange_Menu(ConVar convar, char[] old_value, char[] new_value)
{
    if( convar == INVALID_HANDLE )
    {
        return ;
    }

    char convar_name[64];
    convar.GetName(convar_name, sizeof(convar_name));

    if( strcmp(convar_name, "sm_nr_menu_top_enabled") == 0 )
    {
        cv_menu_top_enabled = convar.BoolValue;
        if( cv_menu_top_enabled )
        {
            Menu_GetAllExtractedData();
        }
    }
    else if( strcmp(convar_name, "sm_nr_menu_top_enabled") == 0 )
    {
        cv_menu_top10_enabled = convar.BoolValue;
    }
    else if( strcmp(convar_name, "sm_nr_menu_prefs_enabled") == 0 )
    {
        cv_menu_prfs_enabled = convar.BoolValue;
        if( cv_menu_prfs_enabled )
        {
            LoadClientPrefs_Menu();
        }
    }
}

void LoadCmd_Menu()
{
    RegConsoleCmd("sm_top",     Cmd_Menu_Catalog,   "show rank catalog menu");
    RegConsoleCmd("sm_rank",    Cmd_Menu_Catalog,   "show rank catalog menu");
    RegConsoleCmd("sm_wr",      Cmd_Menu_Catalog,   "show rank catalog menu");
    RegConsoleCmd("sm_top10",   Cmd_Printer_Top10,  "show top10");
    RegConsoleCmd("sm_rank10",  Cmd_Printer_Top10,  "show top10");
    RegConsoleCmd("sm_wr10",    Cmd_Printer_Top10,  "show top10");
}

void LoadClientPrefs_Menu()
{
    if( protect_client_prefs != INVALID_HANDLE )
    {
        delete protect_client_prefs;
    }

    if( cv_menu_prfs_enabled )
    {
        protect_client_prefs = new Cookie("nmrih-record clientPrefs", "nmrih-record clientPrefs", CookieAccess_Private);
        SetCookieMenuItem(CustomCookieMenu_Menu, 0, "NMRIH Record");
    }
}

Action Cmd_Menu_Catalog(int client, int args)
{
    if( ! cv_menu_top_enabled && ! cv_menu_prfs_enabled )
    {
        PrintToServer("nmrih record menu is disabled.");
        return Plugin_Handled;
    }

    if( ! client )
    {
        ReplyToCommand(client, "In-game command only.");
        return Plugin_Handled;
    }

    if( protect_menu_public_menu == INVALID_HANDLE )
    {
        ReplyToCommand(client, "%t", "Menu Invalid", "Chat Head");
        return Plugin_Handled;
    }

    char item_display[128];
    Menu menu = new Menu(MenuHandler_Catalog, MenuAction_Select | MenuAction_End);
    menu.ExitBackButton = false;
    menu.SetTitle("%T - %T", "Menu Title Head", client, "Menu Catalog title", client, PLUGIN_VERSION);

    if( cv_menu_top_enabled )
    {
        FormatEx(item_display, sizeof(item_display), "%T", "Menu Catalog item_maps", client);
        menu.AddItem("Menu Catalog item_maps", item_display);
    }

    if( cv_menu_prfs_enabled && LibraryExists("clientprefs") )
    {
        FormatEx(item_display, sizeof(item_display), "%T", "Menu Catalog item_prefs", client);
        menu.AddItem("Menu Catalog item_prefs", item_display);
    }

    menu.Display(client, Menu_GetShowTime(client));
    return Plugin_Handled;
}

int MenuHandler_Catalog(Menu menu, MenuAction action, int param1, int param2)
{
    switch( action )
    {
        case MenuAction_End:
        {
            delete menu;
            return 0;
        }
        case MenuAction_Select:
        {
            char item_info[MAX_MAP_NAME_LEN];   // map_name
            menu.GetItem(param2, item_info, 64);

            if( strcmp("Menu Catalog item_maps", item_info) == 0 )
            {
                Menu menu_maps;
                protect_menu_public_menu.GetValue(KEY_MAPS, menu_maps);
                menu_maps.SetTitle("%T - %T", "Menu Title Head", param1, "Menu Maps title", param1, protect_map_map_name, protect_obj_chain_md5, nr_player_func.spawn_tolerance_time, nr_player_func.spawn_penalty_factor * 100.0);
                menu_maps.Display(param1, Menu_GetShowTime(param1));
            }
            else if( strcmp("Menu Catalog item_prefs", item_info) == 0 )
            {
                ShowCookieMenu(param1);
            }
        }
    }
    return 0;
}

void CustomCookieMenu_Menu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    ShowMenu_ClientPrefs(client, 0);
}

void ShowMenu_ClientPrefs(int client, int at=0)
{
    Menu menu_cookie = new Menu(MenuHandler_Cookies, MenuAction_Select | MenuAction_Cancel);
    menu_cookie.ExitBackButton = true;
    menu_cookie.SetTitle("%T%T", "Menu Title Head", client, "Menu Prefs title", client);

    char item_info[16], item_display[128];
    bool item_flag;

    item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_MENU_TIME ? true : false;
    FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_MENU_TIME", client, item_flag ? "Yes" : "No", client);
    IntToString(CLIENT_PREFS_BIT_SHOW_MENU_TIME, item_info, sizeof(item_info));
    menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);

    if( cv_printer_show_play_time )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_WELCOME ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_WELCOME, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_WELCOME", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_extraction_time )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_EXTRACTION_RANK ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_EXTRACTION_RANK, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_EXTRACTION_RANK", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_obj_chain_md5 )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_OBJ_CHAIN_MD5 ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_OBJ_CHAIN_MD5, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_OBJ_CHAIN_MD5", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_obj_start )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_OBJ_START ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_OBJ_START, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_OBJ_START", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_wave_max )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_WAVE_MAX ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_WAVE_MAX, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_WAVE_MAX", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_wave_start )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_WAVE_START ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_WAVE_START, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_WAVE_START", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_extraction_begin )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_EXTRACTION_BEGIN ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_EXTRACTION_BEGIN, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_EXTRACTION_BEGIN", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_player_extraction )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_PLAYER_EXTRACTION ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_PLAYER_EXTRACTION, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_PLAYER_EXTRACTION", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }

    if( cv_printer_show_watermelon_rescue )
    {
        item_flag = nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_WATERMELON_RESCURE ? true : false;
        IntToString(CLIENT_PREFS_BIT_SHOW_WATERMELON_RESCURE, item_info, sizeof(item_info));
        FormatEx(item_display, sizeof(item_display), "%T - %T", "Menu Prefs SHOW_WATERMELON_RESCURE", client, item_flag ? "Yes" : "No", client);
        menu_cookie.AddItem(item_info, item_display, ITEMDRAW_DEFAULT);
    }
    menu_cookie.DisplayAt(client, at, Menu_GetShowTime(client));
}

int MenuHandler_Cookies(Menu menu, MenuAction action, int param1, int param2)
{
    switch( action )
    {
        case MenuAction_Cancel:
        {
            delete menu;
            switch( param2 )
            {
                case MenuCancel_ExitBack:
                {
                    ShowCookieMenu(param1);
                }
            }
            return 0;
        }
        case MenuAction_Select:
        {
            char item_info[16];   // int - bit info
            menu.GetItem(param2, item_info, sizeof(item_info));

            nr_player_data[param1].prefs ^= StringToInt(item_info);
            protect_client_prefs.SetInt(param1, nr_player_data[param1].prefs);

            ShowMenu_ClientPrefs(param1, RoundToFloor(Logarithm(StringToFloat(item_info), 2.0)) / 7 * 7);
        }
    }
    return 0;
}

Action Cmd_Printer_Top10(int client, int args)
{
    if( cv_menu_top10_enabled )
    {
        PrintToServer("nmrih record top10 command is disabled.");
        return Plugin_Handled;
    }

    char key[MAX_MAP_NAME_LEN * 2];
    FormatEx(key, MAX_MAP_NAME_LEN * 2, "%s%s%s", protect_map_map_name, KEY_MARK_CONNECTOR, protect_obj_chain_md5);
    if( protect_player_all_datas.ContainsKey(key) )
    {
        ArrayList t_ranks;
        rank_data t_rank_data;
        protect_player_all_datas.GetValue(key, t_ranks);
        int len = t_ranks.Length;

        CReplyToCommand(client, "%t", "Cmd Top10_CurrentRound", "Chat Head", len, protect_map_map_name, protect_obj_chain_md5);

        int time_minute;
        float time_seconds;
        for(int i=0; i<10 && i<len; ++i)
        {
            t_ranks.GetArray(i, t_rank_data);
            time_minute = RoundToFloor( t_rank_data.take_time / 60.0 );
            time_seconds = t_rank_data.take_time % 60.0;
            CReplyToCommand(client, "%t", "Cmd Top10_Data", "Chat Head", i+1, time_minute, time_seconds, t_rank_data.name);
        }
    }
    else
    {
        CReplyToCommand(client, "%t", "Cmd Top10_Empty", "Chat Head", protect_map_map_name, protect_obj_chain_md5);
    }
    return Plugin_Handled;
}

int MenuHandler_Maps(Menu menu, MenuAction action, int param1, int param2)
{
    switch( action )
    {
        case MenuAction_Cancel:
        {
            switch( param2 )
            {
                case MenuCancel_ExitBack:
                {
                    FakeClientCommandEx(param1, "say /top");
                }
            }
        }
        case MenuAction_Select:
        {
            char item_info[MAX_MAP_NAME_LEN];   // map_name
            menu.GetItem(param2, item_info, MAX_MAP_NAME_LEN);

            Menu menu_routes;
            protect_menu_public_menu.GetValue(item_info, menu_routes);
            menu_routes.SetTitle("%T - %T", "Menu Title Head", param1, "Menu Obj_chain title", param1, item_info);
            menu_routes.Display(param1, Menu_GetShowTime(param1));
        }
    }
    return 0;
}

int MenuHandler_Routes(Menu menu, MenuAction action, int param1, int param2)
{
    switch( action )
    {
        case MenuAction_Cancel:
        {
            switch( param2 )
            {
                case MenuCancel_ExitBack:
                {
                    Menu menu_maps;
                    protect_menu_public_menu.GetValue(KEY_MAPS, menu_maps);
                    menu_maps.SetTitle("%T - %T", "Menu Title Head", param1, "Menu Maps title", param1, protect_map_map_name, protect_obj_chain_md5, nr_player_func.spawn_tolerance_time, nr_player_func.spawn_penalty_factor * 100.0);
                    menu_maps.Display(param1, Menu_GetShowTime(param1));
                }
            }
        }
        case MenuAction_Select:
        {
            char item_info[MAX_MAP_NAME_LEN];   // map_name obj_chain_md5
            menu.GetItem(param2, item_info, MAX_MAP_NAME_LEN);

            int index_split_mark;
            char map_name[MAX_MAP_NAME_LEN], obj_chain_md5[MAX_MAP_NAME_LEN];
            index_split_mark = SplitString(item_info, KEY_MARK_CONNECTOR, map_name, MAX_MAP_NAME_LEN);
            strcopy(obj_chain_md5, MAX_MAP_NAME_LEN, item_info[index_split_mark]);

            Menu menu_ranks;
            protect_menu_public_menu.GetValue(item_info, menu_ranks);
            menu_ranks.SetTitle("%T - %T", "Menu Title Head", param1, "Menu Rank title", param1, map_name, obj_chain_md5);
            menu_ranks.Display(param1, Menu_GetShowTime(param1));
        }
    }
    return 0;
}

int MenuHandler_Ranks(Menu menu, MenuAction action, int param1, int param2)
{
    switch( action )
    {
        case MenuAction_Cancel:
        {
            switch( param2 )
            {
                case MenuCancel_ExitBack :
                {
                    char item_info[MAX_MAP_NAME_LEN];   // map_name
                    menu.GetItem(0, item_info, MAX_MAP_NAME_LEN);

                    Menu menu_routes;
                    protect_menu_public_menu.GetValue(item_info, menu_routes);
                    menu_routes.Display(param1, Menu_GetShowTime(param1));
                }
            }
        }
        // case MenuAction_Select:
    }
    return 0;
}

int Menu_GetShowTime(int client)
{
    return nr_player_data[client].prefs & CLIENT_PREFS_BIT_SHOW_MENU_TIME ? 30 : 0;
}

/**
 * 查询并暂存所有撤离数据
 *
 * @return                  No
 */
public void Menu_GetAllExtractedData()
{
    char sql_str[1024];     // recommend: 1024
    FormatEx(sql_str, sizeof(sql_str)
        , "SELECT map_name, obj_chain_md5, round_len, round_begin_time, spawn_time, engine_time, name, d.steam_id, spawn_time<=round_begin_time completed, IF((spawn_time<=round_begin_time+%f), engine_time-round_begin_time, (engine_time-round_begin_time)*%f) take_time \
FROM map_info m \
INNER JOIN round_info r ON m.id=r.map_id \
INNER JOIN round_data d ON r.id=d.round_id \
INNER JOIN player_name pn ON d.steam_id = pn.steam_id \
WHERE d.reason='extracted' \
ORDER BY map_name, obj_chain_md5, take_time, name"
        , nr_player_func.spawn_tolerance_time, nr_player_func.spawn_penalty_factor + 1.0
    );

    nr_dbi.db.Query(CB_asyncGetAllExtractedData, sql_str, _, DBPrio_Low); // 特定回调
}

void CB_asyncGetAllExtractedData(Database db, DBResultSet results, const char[] error, any data)
{
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' )
    {
        Free_all_datas();

        protect_player_all_datas = new StringMap();
        protect_player_round_datas = new StringMap();
        ArrayList   t_maps = new ArrayList(MAX_MAP_NAME_LEN);
        ArrayList   t_routes,                           t_ranks;
        int         t_field_index,                      round_len;
        char        map_name[MAX_MAP_NAME_LEN],         obj_chain_md5[MAX_MAP_NAME_LEN];
        char        key_ranks[MAX_MAP_NAME_LEN * 2],    key_round_len[MAX_MAP_NAME_LEN * 2];

        protect_player_all_datas.SetValue(KEY_MAPS, t_maps);  // save

        while( results.FetchRow() )
        {
            rank_data t_rank_data;

            results.FieldNameToNum(FIELD_NAME_MAP_NAME, t_field_index);
            results.FetchString(t_field_index, map_name, MAX_MAP_NAME_LEN);

            results.FieldNameToNum(FIELD_NAME_OBJ_CHAIN_MD5, t_field_index);
            results.FetchString(t_field_index, obj_chain_md5, MAX_MAP_NAME_LEN);

            FormatEx(key_ranks, MAX_MAP_NAME_LEN * 2, "%s%s%s", map_name, KEY_MARK_CONNECTOR, obj_chain_md5);

            results.FieldNameToNum(FIELD_NAME_ROUND_LEN, t_field_index);
            round_len = results.FetchInt(t_field_index);

            FormatEx(key_round_len, MAX_MAP_NAME_LEN * 2, "%s%s%s", key_ranks, KEY_MARK_CONNECTOR, KEY_MARK_ROUND_DATA_LEN);

            results.FieldNameToNum(FIELD_NAME_ROUND_BEGIN_TIME, t_field_index);
            t_rank_data.round_begin_time = results.FetchFloat(t_field_index);

            results.FieldNameToNum(FIELD_NAME_EXTRACTION_BEGIN_TIME, t_field_index);
            t_rank_data.extraction_begin_time = results.FetchFloat(t_field_index);

            results.FieldNameToNum(FIELD_NAME_SPAWN_TIME, t_field_index);
            t_rank_data.spawn_time = results.FetchFloat(t_field_index);

            results.FieldNameToNum(FIELD_NAME_ENGINE_TIME, t_field_index);
            t_rank_data.engine_time = results.FetchFloat(t_field_index);

            results.FieldNameToNum(FIELD_NAME_NAME, t_field_index);
            results.FetchString(t_field_index, t_rank_data.name, MAX_NAME_LENGTH);

            results.FieldNameToNum(FIELD_NAME_STEAM_ID, t_field_index);
            t_rank_data.steam_id = results.FetchInt(t_field_index);

            results.FieldNameToNum(FIELD_NAME_COMPLETED, t_field_index);
            t_rank_data.completed = results.FetchInt(t_field_index) == 1;

            results.FieldNameToNum(FIELD_NAME_TAKE_TIME, t_field_index);
            t_rank_data.take_time = results.FetchFloat(t_field_index);

            // save
            if( protect_player_all_datas.ContainsKey(map_name) )
            {
                protect_player_all_datas.GetValue(map_name, t_routes);        // 读取当前地图的所有路线

                if( protect_player_all_datas.ContainsKey(key_ranks) )
                {
                    protect_player_all_datas.GetValue(key_ranks, t_ranks);    // 读取当前路线排行榜
                    t_ranks.PushArray(t_rank_data);
                }
                else
                {
                    t_ranks = new ArrayList(sizeof(rank_data));

                    t_routes.PushString(obj_chain_md5);
                    t_ranks.PushArray(t_rank_data);

                    protect_player_all_datas.SetValue(key_ranks, t_ranks);
                    protect_player_round_datas.SetValue(key_round_len, round_len);
                }
            }
            else
            {
                t_ranks = new ArrayList(sizeof(rank_data));
                t_routes = new ArrayList(MAX_MAP_NAME_LEN);

                t_maps.PushString(map_name);
                t_routes.PushString(obj_chain_md5);
                t_ranks.PushArray(t_rank_data);

                protect_player_all_datas.SetValue(map_name, t_routes);
                protect_player_all_datas.SetValue(key_ranks, t_ranks);
                protect_player_round_datas.SetValue(key_round_len, round_len);
            }
        }
        Free_all_public_menus();
        Traversal_AllData_CreatePublicMenu();
    }
    else
    {
        LogError(PREFIX_DBI..."CB_asyncGetAllExtracted_sqlStr | db:%d | result:%d | Error: %s |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
    }
}

void Free_all_datas()
{
    if( protect_player_all_datas != INVALID_HANDLE )
    {
        StringMapSnapshot keys = protect_player_all_datas.Snapshot();
        int len_keys = keys.Length;
        char key_name[MAX_MAP_NAME_LEN * 2];
        ArrayList tmp;

        for(int i=0; i<len_keys; ++i)
        {
            keys.GetKey(i, key_name, MAX_MAP_NAME_LEN * 2);
            protect_player_all_datas.GetValue(key_name, tmp);
            if( tmp != INVALID_HANDLE )
            {
                delete tmp;
            }
        }
        delete protect_player_all_datas;
    }

    if( protect_player_round_datas != INVALID_HANDLE )
    {
        delete protect_player_round_datas;
    }
}

void Traversal_AllData_CreatePublicMenu()
{
    ArrayList t_maps, t_routes, t_ranks;
    rank_data t_rank_data;
    int round_len;
    int len_t_maps, len_t_routes, len_t_ranks;
    char map_name[MAX_MAP_NAME_LEN], obj_chain_md5[MAX_MAP_NAME_LEN];
    char key_ranks[MAX_MAP_NAME_LEN * 2], key_round_len[MAX_MAP_NAME_LEN * 2];

    protect_player_all_datas.GetValue(KEY_MAPS, t_maps);
    len_t_maps = t_maps.Length;

    protect_menu_public_menu = new StringMap();
    Menu menu_maps = new Menu(MenuHandler_Maps, MenuAction_Select | MenuAction_Cancel);
    menu_maps.ExitBackButton = true;
    protect_menu_public_menu.SetValue(KEY_MAPS, menu_maps);

    Menu menu_routes, menu_ranks;
    char item_display[MAX_MAP_NAME_LEN * 2];

    for(int i=0; i<len_t_maps; ++i)
    {
        t_maps.GetString(i, map_name, MAX_MAP_NAME_LEN);

        protect_player_all_datas.GetValue(map_name, t_routes);
        len_t_routes = t_routes.Length;

        menu_maps.AddItem(map_name, map_name, ITEMDRAW_DEFAULT);

        if( protect_menu_public_menu.ContainsKey(map_name) )
        {
            protect_menu_public_menu.GetValue(map_name, menu_routes);
        }
        else
        {
            menu_routes = new Menu(MenuHandler_Routes, MenuAction_Select | MenuAction_Cancel);
            menu_routes.ExitBackButton = true;
            protect_menu_public_menu.SetValue(map_name, menu_routes);
        }

        for(int j=0; j<len_t_routes; ++j)
        {
            t_routes.GetString(j, obj_chain_md5, MAX_MAP_NAME_LEN);

            FormatEx(key_ranks, MAX_MAP_NAME_LEN * 2, "%s%s%s", map_name, KEY_MARK_CONNECTOR, obj_chain_md5);
            protect_player_all_datas.GetValue(key_ranks, t_ranks);
            len_t_ranks = t_ranks.Length;

            FormatEx(key_round_len, MAX_MAP_NAME_LEN * 2, "%s%s%s", key_ranks, KEY_MARK_CONNECTOR, KEY_MARK_ROUND_DATA_LEN);
            protect_player_round_datas.GetValue(key_round_len, round_len);


            menu_routes.AddItem(key_ranks, obj_chain_md5, ITEMDRAW_DEFAULT);

            if( protect_menu_public_menu.ContainsKey(key_ranks) )
            {
                protect_menu_public_menu.GetValue(key_ranks, menu_ranks);
            }
            else
            {
                menu_ranks = new Menu(MenuHandler_Ranks, MenuAction_Cancel);
                menu_ranks.ExitBackButton = true;
                protect_menu_public_menu.SetValue(key_ranks, menu_ranks);
            }

            for(int k=0; k<len_t_ranks; ++k)
            {
                t_ranks.GetArray(k, t_rank_data);
                FormatEx(item_display, sizeof(item_display), "| %02d | %02dm %05.2fs | %s"
                    , k + 1
                    , RoundToFloor(t_rank_data.take_time / 60.0)
                    , t_rank_data.take_time % 60.0
                    , t_rank_data.name
                );
                menu_ranks.AddItem(map_name, item_display, ITEMDRAW_DISABLED);   // Todo: 唯一标识
            }
        }
    }
}

void Free_all_public_menus()
{
    if( protect_menu_public_menu != INVALID_HANDLE )
    {
        StringMapSnapshot keys = protect_menu_public_menu.Snapshot();
        int len_keys = keys.Length;
        char key_name[MAX_MAP_NAME_LEN * 2];
        Menu tmp;

        for(int i=0; i<len_keys; ++i)
        {
            keys.GetKey(i, key_name, MAX_MAP_NAME_LEN * 2);
            protect_menu_public_menu.GetValue(key_name, tmp);
            if( tmp != INVALID_HANDLE )
            {
                delete tmp;
            }
        }
        delete protect_menu_public_menu;
    }
}

int GetClientPrefsIntValue(int client)
{
    if( cv_menu_prfs_enabled && protect_client_prefs != INVALID_HANDLE )
    {
        return protect_client_prefs.GetInt(client, CLIENT_PREFS_BIT_DEFAULT);
    }
    return 0;
}