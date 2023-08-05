#pragma newdecls required
#pragma semicolon 1

#define         PREFIX_MAP                      "[NR-map] "
#define         MAX_MAP_NAME_LEN                64

enum MAP_TYPE {
    MAP_TYPE_NMO = 0,
    MAP_TYPE_NMS = 1,
    MAP_TYPE_Orther = 2
}

char            protect_map_map_name[MAX_MAP_NAME_LEN];
int             private_map_map_id;
float           private_map_start_time;
float           private_map_end_time;
MAP_TYPE        private_map_map_type;

methodmap NRMap __nullable__
{
    public NRMap() {
        return view_as<NRMap>(true);
    }

    property int map_id {
        public get()                    { return private_map_map_id; }
        public set(int value)           { private_map_map_id = value; }
    }

    property float start_time {
        public get()                    { return private_map_start_time; }
        public set(float value)         { private_map_start_time = value; }
    }

    property float end_time {
        public get()                    { return private_map_end_time; }
        public set(float value)         { private_map_end_time = value; }
    }

    property MAP_TYPE map_type {
        public get()                    { return private_map_map_type; }
        public set(MAP_TYPE value)     { private_map_map_type = value; }
    }

    /**
     * OnMapStart 时, 新增的地图数据
     * 返回字符串, 可用于异步执行. Length = 52 - 4 + float + MAX_MAP_LEN
     * min: 128
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     *
     * @return                  No
     */
    public void insNewMap_sqlStr(char[] sql_str, int max_length) {
        this.map_id = 0;
        this.start_time = GetEngineTime();
        this.end_time = 0.0;

        GetCurrentMap(protect_map_map_name, MAX_MAP_NAME_LEN);
        if( strncmp(protect_map_map_name, "nmo_", 4) == 0 ) {
            this.map_type = MAP_TYPE_NMO;
        }
        else if( strncmp(protect_map_map_name, "nms_", 4) == 0 ) {
            this.map_type = MAP_TYPE_NMS;
        }
        else {
            this.map_type = MAP_TYPE_Orther;
        }

        FormatEx(sql_str, max_length, "INSERT INTO map_info SET map_name='%s', start_time=%f", protect_map_map_name, this.start_time);
    }

    /**
     * OnMapEnd 时, 更新的地图数据 (end_time)
     * 返回字符串, 可用于异步执行. Length = 52 - 4 + float + int
     * min: 68
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     *
     * @return                  No
     */
    public void updMapEnd_sqlStr(char[] sql_str, int max_length) {
        this.end_time = GetEngineTime();
        FormatEx(sql_str, max_length, "UPDATE map_info SET end_time=%f WHERE id=%d LIMIT 1", this.end_time, this.map_id);
    }
}


NRMap nr_map;
