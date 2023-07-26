#pragma newdecls required
#pragma semicolon 1


#define BIT_CATEGORY_kill_cnt      1
#define BIT_CATEGORY_inflict_dmg    2
#define BIT_CATEGORY_hurt_cnt      4
#define BIT_CATEGORY_hurt_dmg      8
// #define BIT_CATEGORY_5      "16"
// #define BIT_CATEGORY_6      "32"

#define MAX_ITEM_INFO               16
#define MAX_ITEM_DISTLAY            32

void LoadHook_Menu()
{
    RegConsoleCmd("sm_top", Cmd_top, "show top menu");
}

Action Cmd_top(int client, int args)
{
    if( ! client )
    {
        ReplyToCommand(client, "In-game command only.");
        return Plugin_Handled;
    }

    return Plugin_Handled;
}


void Menu_category(int client)
{
    char map_name[MAX_MAP_NAME_LEN];
    GetCurrentMap(map_name, sizeof(map_name));

    Menu menu_category = new Menu(Handler_category);
    menu_category.SetTitle("%T", "MenuTitle", client, map_name);
    // menu.ExitBackButton = true;
    additem_category(menu, BIT_CATEGORY_kill_cnt,       "Menu Category killCnt",    client, nr_player_data[client].kill_cnt_total);
    additem_category(menu, BIT_CATEGORY_inflict_dmg,    "Menu Category inflictDmg", client, nr_player_data[client].inflict_dmg_total);
    additem_category(menu, BIT_CATEGORY_hurt_cnt,       "Menu Category hurtCnt",    client, nr_player_data[client].hurt_cnt_total);
    additem_category(menu, BIT_CATEGORY_hurt_dmg,       "Menu Category hurtDmg",    client, nr_player_data[client].hurt_dmg_total);
}

void additem_category(Menu menu, int item_info, char[] item_display_phrases, any...)
{
    char item_info_str[MAX_ITEM_INFO], item_display[MAX_ITEM_DISTLAY];
    IntToString(item_info, item_info_str, MAX_ITEM_INFO);
    VFormat(item_display, MAX_ITEM_DISTLAY, "%T", 3);
    menu.AddItem(item_info_str, item_display, ITEMDRAW_DEFAULT);
}

int Handler_category(Menu menu, MenuAction action, int param1, int param2)
{
    switch ( action )
    {
        case MenuAction_Select:
        {
            char item_info_str[10];
            menu.GetItem(param2, item_info_str, sizeof(item_info_str));
            int item_info = StringToInt(item_info_str);
            switch( item_info )
            {
                case BIT_CATEGORY_kill_cnt:
                {
                    Menu_category
                }
            }
        }
        case MenuAction_Cancel:
        {
            if( ! IsValidClient(param1) )
            {
                return 0;
            }

            switch ( param2 )
            {
                // case MenuCancel_Disconnected:
                // case MenuCancel_Interrupted:
                // case MenuCancel_Exit:
                // case MenuCancel_NoDisplay:
                // case MenuCancel_Timeout:
                // case MenuCancel_ExitBack:
            }
        }
        /* If the menu has ended, destroy it */
        case MenuAction_End:
        {
            if( menu == INVALID_HANDLE )
            {
                delete menu;
            }
        }
    }
    return 0;
}
