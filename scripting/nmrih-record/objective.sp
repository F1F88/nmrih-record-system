#pragma newdecls required
#pragma semicolon 1

#define     PREFIX_OBJECTIVE            "[NR-objective] "
#define     MAX_USERMSG_LEN             256
#define     MAX_OBJNOTIFY_LEN           MAX_USERMSG_LEN
#define     MAX_OBJ_CHAIN_STR_LEN       256

char        protect_obj_chain[MAX_OBJ_CHAIN_STR_LEN]
            , protect_obj_chain_md5[MAX_MD5_LEN];

methodmap NRObjective __nullable__
{
    public NRObjective()  {
        return view_as<NRObjective>(true);
    }

    property int obj_serial {
        public get()                    { return objMgr.currentObjectiveIndex + 1; }
    }

    property int obj_chain_len {
        public get()                    { return objectiveChain.Length; }
    }

    property int obj_id {
        public get()                    { return objectiveChain.Get(objMgr.currentObjectiveIndex); }
    }

    property int wave_serial {
        public get()                    { return GetEntProp(FindEntityByClassname(-1, "wave_status"), Prop_Send, "_waveNumber"); }
    }

    property int wave_end {
        public get()                    { return GetEntProp(FindEntityByClassname(-1, "overlord_wave_controller"), Prop_Data, "m_iEndWave"); }
    }

    /**
     * 获取任务链ID组成的字符串
     *
     * @param obj_chain_str     存储返回的任务链ID字符串
     * @param max_length        obj_chain_str 的长度
     * @param sep               每个任务ID之间的分隔符 (默认不分隔)
     *
     * @return                  No
     */
    public void GetObjectiveChainIDString(char[] obj_chain_str, int max_length, const char[] sep) {
        if( this.obj_chain_len > 0 ) {
            IntToString(objectiveChain.Get(0), obj_chain_str, max_length);
        }
        for(int i=1; i < objectiveChain.Length; ++i) {
            Format(obj_chain_str, max_length, "%s%s%d", obj_chain_str, sep, objectiveChain.Get(i));
        }
    }

    /**
     * 获取任务链ID字符串的md5值 (可作为唯一索引)
     *
     * @param obj_chain_str     任务链ID字符串
     * @param obj_chain_md5     存储返回的任务链ID字符串的MD5值
     * @param max_length        obj_chain_md5 的长度 (md5值为32位, 确保数组大小 >= 33 即可)
     *
     * @return                  No
     */
    public void GetObjectiveChainMD5(char[] obj_chain_str, char[] obj_chain_md5, int max_length) {
        Crypt_MD5(obj_chain_str, obj_chain_md5, max_length);
    }

    /**
     * 记录新的任务 (可与 记录新的撤离开始 共用)
     * NMO: 由用户信息 ObjectiveNotify 触发
     * NMS: 由事件 new_wave 触发
     * 返回字符串, 可用于异步执行. Length = 65 - 6 + int(3) * 3 + int(10) + float + MAX_OBJNOTIFY_LEN
     * min: 349
     * recommend: 384
     *
     * @param db                数据库对象. 用于转义 obj_info
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param obj_info          任务信息 (NMS地图为NULL_STRING, 撤离开始时为extraction_begin)
     * @param resupply          Wave是否触发resupply(NMS外为0)
     *
     * @return                  No
     * @error                   Invalid database handle
     */
    public void insNewObjective_sqlStr(Database db, char[] sql_str, int max_length, const char[] obj_info, const int resupply=-1) {
        if( db == INVALID_HANDLE ) {
            ThrowError(PREFIX_OBJECTIVE..."insNewObjective_sqlStr Database == INVALID_HANDLE.");
        }
        char obj_info_escape[MAX_OBJNOTIFY_LEN];
        db.Escape(obj_info, obj_info_escape, MAX_OBJNOTIFY_LEN);
        if( nr_map.map_type == MAP_TYPE_NMO ) {
            FormatEx(sql_str, max_length, "INSERT INTO objective_info VALUES(NULL,%d,%f,%d,%d,'%s',-1,NOW())", nr_round.round_id, GetEngineTime(), this.obj_serial, this.obj_id, obj_info_escape);
        }
        else if( nr_map.map_type == MAP_TYPE_NMS ) {
            FormatEx(sql_str, max_length, "INSERT INTO objective_info VALUES(NULL,%d,%f,%d,-1,'%s',%d,NOW())", nr_round.round_id, GetEngineTime(), this.wave_serial, NULL_STRING, resupply);
        }
    }
}


void LoadHook_Objective()
{
    // * 获取任务信息, 传递给数据库, 并在聊天框打印任务进度 (ObjectiveNotify 在 objective_complete 之后输出)
    // * 存在问题:
    // *    第一个任务 objective_complete 不会触发, 而 UserMsg_Objective 会
    // *    最后一个任务 objective_complete 会触发, 而 UserMsg_Objective 不会
    // * 解决方案: 舍弃 objective_completel, 使用 extraction_begin 补全最后一个任务的信息输出
    HookUserMessage(    GetUserMessageId(   "ObjectiveNotify"   ),          UserMsg_Objective);
    // HookUserMessage(    GetUserMessageId(   "ObjectiveUpdate"   ),          UserMsg_Objective);
    HookEvent("new_wave",                   On_new_wave,                    EventHookMode_Post);
    HookEvent("watermelon_rescue",          On_watermelon_rescue,           EventHookMode_Post);
}


NRObjective nr_objective;


/* obj-mng */
public void ObjectiveBoundary_Finish(Address addr)
{
    SDKCall(boundaryFinishFn, addr);
}

public void ObjectiveManager_StartNextObjective(Address addr)
{
    SDKCall(startNextObjectiveFn, addr);
}

int GetOffsetOrFail(GameData gamedata, const char[] key)
{
    int offset = gamedata.GetOffset(key);
    if (offset == -1)
    {
        SetFailState("Failed to find offset \"%s\"", key);
    }
    return offset;
}

void LoadGamedata()
{
    GameData gamedata = new GameData("nmo-guard.games");
    if(!gamedata) {
        SetFailState("Failed to load gamedata");
    }

    ObjectiveManager_LoadGameData(gamedata);
    delete gamedata;

    objectiveChain = new ArrayList();
}

void UpdateObiChain()
{
    if( ! objMgr )
    {
        LogError(PREFIX_OBJECTIVE..."Called objMgr.objectiveChain but objMgr is null");
        return ;
    }
    objectiveChain.Clear();
    objMgr.GetObjectiveChain(objectiveChain);
}