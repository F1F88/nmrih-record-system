#pragma newdecls required
#pragma semicolon 1

#define         PREFIX_DBI                      "[NR-dbi] "
#define         BIT_G_SYNC_DATABASE             1
#define         BIT_G_ASYNC_DATABASE            2
#define         MAX_DATABSE_NAME_LEN            32
#define         MAX_TABLE_NAME_LEN              32
#define         MAX_DRIVER_LEN                  32
#define         MAX_ERROR_LEN                   256
#define         MAX_SQL_LEN                     2048

Database        private_dbi_db;                 // ! 使用异步操作时注意线程安全问题
Handle          private_dbi_timer_keep_alive;


char            cv_dbi_conf_name[32];
bool            cv_dbi_keep_alive;
float           cv_dbi_keep_alive_interval;

methodmap NRDbi __nullable__
{
    public NRDbi() {
        return view_as<NRDbi>(true);
    }

    property Database db {
        public get()                            { return view_as<Database>(private_dbi_db); }
        public set(Database value)              { private_dbi_db = value; }
    }

    property Handle timer_keep_alive {
        public get()                            { return view_as<Handle>(private_dbi_timer_keep_alive); }
        public set(Handle value)                { private_dbi_timer_keep_alive = value; }
    }

    /**
     * 连接数据库, 必须在其他操作之前执行 !
     *
     * @param conf_name         连接数据库的配置名称. 需要填写在 sourcemod/configs/databases.cfg 中
     * @param persistent        True to re-use a previous persistent connection if possible, false otherwise.
     *
     * @return                  No
     * @error                   connect failure
     */
    public void connectSyncDatabase(const char[] conf_name, bool persistent=true) {
        char error[MAX_ERROR_LEN];
        this.db = SQL_Connect(conf_name, persistent, error, MAX_ERROR_LEN);
        if( this.db == null || this.db == INVALID_HANDLE ) {
            ThrowError(PREFIX_DBI..."sync connect database fail. | config name: %s | error: %s |", conf_name, error);
        }
        this.setCharset(this.db);
    }

    /**
     * 连接数据库, 必须在其他操作之前执行 !
     *
     * @param conf_name         连接数据库的配置名称. 需要填写在 sourcemod/configs/databases.cfg 中
     * @param persistent        True to re-use a previous persistent connection if possible, false otherwise.
     *
     * @return                  No
     * @error                   connect failure
     */
    public void connectAsyncDatabase(const char[] conf_name, any data=0) {
        Database.Connect(CB_connectAsyncDatabase, conf_name, data);
    }

    public void setCharset(Database db) {
        char driver[MAX_DRIVER_LEN];
        db.Driver.GetIdentifier(driver, MAX_DRIVER_LEN);
        if( StrContains(driver, "mysql", false) ) {
            SQL_SetCharset(db, "utf8mb4");
        }
        else {
            SQL_SetCharset(db, "utf8");
        }
    }

    /**
     * 同步执行预编译语句, 并返回 insert id
     * ! 不推荐, 当数据库重启时预编译语句会失效
     *
     * @param stmt              预编译语句
     *
     * @return                  Last query's insertion id.
     * @error                   Invalid statement Handle OR Exec failure
     */
    public int syncExecPreSQL_GetInt(DBStatement stmt) {
        if( stmt == INVALID_HANDLE ) {
            ThrowError(PREFIX_DBI..."syncExecPreSQL_GetInt stmt == INVALID_HANDLE.");
        }

        SQL_LockDatabase(this.db);
        if( SQL_Execute(stmt) == true ) {
            int ins_id = SQL_GetInsertId(stmt);
            SQL_UnlockDatabase(this.db);
            return ins_id;
        }
        else {
            char error[MAX_ERROR_LEN];
            SQL_GetError(this.db, error, MAX_ERROR_LEN);
            SQL_UnlockDatabase(this.db);
            ThrowError(PREFIX_DBI..."syncExecPreSQL_GetInt Error: %s", error);
        }
    }

    /**
     * 异步执行传入的字符串SQL
     *
     * @param sql_str           SQL 字符串
     * @param sql_len           sql_str length
     * @param prio              Priority queue to use.
     *
     * @return                  No
     * @error                   sql_str length <= 0 OR Exec failure
     */
    public void asyncExecStrSQL(const char[] sql_str, const int sql_len, DBPriority priority=DBPrio_Normal) {
        if( strlen(sql_str) <= 0 || sql_len <= 0 ) {
            ThrowError(PREFIX_DBI..."asyncExecStrSQL sql_str length <= 0.");
        }
        DataPack data = new DataPack();
        data.WriteCell(sql_len);
        data.WriteString(sql_str);
        this.db.Query(CB_asyncExecStrSQL, sql_str, data, priority);
    }

    /**
     * 同步执行传入的字符串SQL, 并返回 Last query's insertion id.
     *
     * @param sql_str           SQL 字符串
     *
     * @return                  Last query's insertion id.
     * @error                   sql_str length <= 0 OR result == INVALID_HANDLE
     */
    public int syncExeStrSQL_GetId(const char[] sql_str) {
        if( strlen(sql_str) <= 0 ) {
            ThrowError(PREFIX_DBI..."syncExeStrSQL_GetId sql_str length <= 0.");
        }

        SQL_LockDatabase(this.db);
        if( SQL_FastQuery(this.db, sql_str) ) {
            int ins_id = SQL_GetInsertId(this.db);
            SQL_UnlockDatabase(this.db);
            return ins_id;
        }
        else {
            char error[MAX_ERROR_LEN];
            SQL_GetError(this.db, error, MAX_ERROR_LEN);
            SQL_UnlockDatabase(this.db);
            ThrowError(PREFIX_DBI..."syncExeStrSQL_GetId result == INVALID_HANDLE | Error: %s | SQL: %s |", error, sql_str);
        }
    }
}


NRDbi nr_dbi;


void CB_connectAsyncDatabase(Database db_new, const char[] error, any data) {
    if( db_new == null || db_new == INVALID_HANDLE ) {
        LogError(PREFIX_DBI..."CB_connectAsyncDatabase failure! | Error: %s", error);
    }
    else {
        nr_dbi.db = db_new;
        nr_dbi.setCharset(nr_dbi.db);
    }
}

void CB_asyncExecStrSQL(Database db, DBResultSet results, const char[] error, DataPack data) {
    if( db != INVALID_HANDLE && results != INVALID_HANDLE && error[0] == '\0' ) {
        if( data != INVALID_HANDLE ) {
            delete data;
        }
    }
    else {
        if( data != INVALID_HANDLE ) {
            data.Reset();
            int sql_len = data.ReadCell();
            char[] sql_str = new char[sql_len];
            data.ReadString(sql_str, sql_len);

            LogError(PREFIX_DBI..."CB_asyncExecStrSQL | db:%d | result:%d | Error: %s | SQL: %s |", db != INVALID_HANDLE, results != INVALID_HANDLE, error, sql_str);
            delete data;
        }
        else {
            LogError(PREFIX_DBI..."CB_asyncExecStrSQL | db:%d | result:%d | Error: %s | data is INVALID_HANDLE |",  db != INVALID_HANDLE, results != INVALID_HANDLE, error);
        }
    }
}

Action Timer_Dbi_KeepAlive(Handle timer, any data) {
    if( nr_dbi.db == null || nr_dbi.db == INVALID_HANDLE) {
        nr_dbi.connectAsyncDatabase(cv_dbi_conf_name, cv_dbi_keep_alive);
    }
    else {
        nr_dbi.asyncExecStrSQL("SELECT 1", 10, DBPrio_Low);
    }
    return Plugin_Continue;
}


public void LoadDBIConVar() {
    ConVar convar;
    (convar = CreateConVar("sm_nr_dbi_config",              "nmrih_record", "Database Config Name of database keyvalue stored in sourcemod/configs/databases.cfg")).AddChangeHook(OnDbiConVarChange);
    convar.GetString(cv_dbi_conf_name, MAX_DATABSE_NAME_LEN);
    (convar = CreateConVar("sm_nr_dbi_keep_alive",          "1",            "是否保持长连接(链接长时间未使用可能断开连接)")).AddChangeHook(OnDbiConVarChange);
    cv_dbi_keep_alive = convar.BoolValue;
    (convar = CreateConVar("sm_nr_dbi_keep_alive_interval", "300",          "保持长连接检查间隔(秒)")).AddChangeHook(OnDbiConVarChange);
    cv_dbi_keep_alive_interval = convar.FloatValue;

    if( cv_dbi_keep_alive ) {
        nr_dbi.timer_keep_alive = CreateTimer(cv_dbi_keep_alive_interval, Timer_Dbi_KeepAlive, _, TIMER_REPEAT);
    }
}

void OnDbiConVarChange(ConVar convar, char[] old_value, char[] new_value) {
    if( convar == INVALID_HANDLE )
        return ;
    char convar_name[64];
    convar.GetName(convar_name, sizeof(convar_name));

    if( strcmp(convar_name, "sm_nr_dbi_config") == 0 ) {
        strcopy(cv_dbi_conf_name, MAX_DATABSE_NAME_LEN, new_value);
    }
    else if( strcmp(convar_name, "sm_nr_dbi_keep_alive") == 0 ) {
        cv_dbi_keep_alive = convar.BoolValue;
        if( cv_dbi_keep_alive ) {
            if( nr_dbi.timer_keep_alive == INVALID_HANDLE ) {
                nr_dbi.timer_keep_alive = CreateTimer(cv_dbi_keep_alive_interval, Timer_Dbi_KeepAlive, _, TIMER_REPEAT);
            }
        }
        else if( nr_dbi.timer_keep_alive != INVALID_HANDLE ) {
            delete nr_dbi.timer_keep_alive;
        }
    }
    else if( strcmp(convar_name, "sm_nr_dbi_keep_alive_interval") == 0 ) {
        cv_dbi_keep_alive_interval = convar.FloatValue;
        if( cv_dbi_keep_alive ) {
            if( nr_dbi.timer_keep_alive != INVALID_HANDLE ) {
                delete nr_dbi.timer_keep_alive;
            }
            nr_dbi.timer_keep_alive = CreateTimer(cv_dbi_keep_alive_interval, Timer_Dbi_KeepAlive, _, TIMER_REPEAT);
        }
    }
}