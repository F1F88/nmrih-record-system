/**
 * 不完全按照 state change ! 太复杂了使用数据库记录可能会导致数据量偏多
 * 只需要能够区分每一个 "回合" 的开始与结束即可
 *
 */
#pragma newdecls required
#pragma semicolon 1

#define         PREFIX_ROUND                "[NR-round] "

int             private_round_round_id;
bool            private_round_practice;
float           private_round_start_time;
float           private_round_begin_time;
float           private_round_extraction_begin_time;
float           private_round_end_time;

methodmap NRRound __nullable__
{
    public NRRound() {
        return view_as<NRRound>(true);
    }

    property int round_id {                 // 在数据表中的 id
        public get()                    { return view_as<int>(private_round_round_id); }
        public set(int value)           { private_round_round_id = value; }
    }

    property bool practice {                // 当前是否为练习时间
        public get()                    { return view_as<bool>(private_round_practice); }
        public set(bool value)          { private_round_practice = value; }
    }

    property float start_time {
        public get()                    { return view_as<float>(private_round_start_time); }
        public set(float value)         { private_round_start_time = value; }
    }

    property float begin_time {
        public get()                    { return view_as<float>(private_round_begin_time); }
        public set(float value)         { private_round_begin_time = value; }
    }

    property float extraction_begin_time {
        public get()                    { return view_as<float>(private_round_extraction_begin_time); }
        public set(float value)         { private_round_extraction_begin_time = value; }
    }

    property float end_time {
        public get()                    { return view_as<float>(private_round_end_time); }
        public set(float value)         { private_round_end_time = value; }
    }

    /**
     * 记录新的回合
     * 新地图的新回合由 practice_ending_time 触发 (practice = true)
     * 其他回合由 nmrih_reset_map 触发 (practice = false)
     * 返回字符串, 可用于异步执行. Length = 98 - 10 + int(2) + int(3) + int(10) + float + 32
     * min: 155
     * recommend: 160
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     * @param obj_length        本回合 任务链/wave_end
     * @param obj_chain_md5     本回合 任务链/地图名称 md5值
     *
     * @return                  No
     */
    public void insNewRound_sqlStr(char[] sql_str, int max_length, const int round_len, const char[] obj_chain_md5) {
        this.round_id = 0;
        this.start_time = GetEngineTime();
        this.begin_time = 0.0;
        this.extraction_begin_time = 0.0;
        this.end_time = 0.0;
        FormatEx(sql_str, max_length
            , "INSERT INTO round_info SET map_id=%d, practice=%d, start_time=%f, round_len=%d, obj_chain_md5='%s'"
            , nr_map.map_id,    this.practice,    this.start_time,    round_len,    obj_chain_md5
        );
    }

    /**
     * 更新 round_begin_time (仅在 nmrih_round_begin 更新回合开始时间)
     * 返回字符串, 可用于异步执行. Length = 61 - 4 + float + int
     * min: 80
     * recommend: 128
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     *
     * @return                  No
     */
    public void updRoundBegin_sqlStr(char[] sql_str, int max_length) {
        this.begin_time = GetEngineTime();
        FormatEx(sql_str, max_length, "UPDATE round_info SET round_begin_time=%f WHERE id=%d LIMIT 1", this.begin_time, this.round_id);
    }

    /**
     * 更新 extraction_begin_time (仅在 nmrih_round_begin 更新回合撤离开始时间)
     * 返回字符串, 可用于异步执行. Length = 67 - 4 + float + int
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     *
     * @return                  No
     */
    public void updRoundExtractionBegin_sqlStr(char[] sql_str, int max_length) {
        this.extraction_begin_time = GetEngineTime();
        FormatEx(sql_str, max_length, "UPDATE round_info SET extraction_begin_time=%f WHERE id=%d LIMIT 1", this.extraction_begin_time, this.round_id);
    }

    /**
     * 更新 end_time
     * OnMapEnd: 仅更新 end_time
     * On_nmrih_practice_ending: 如果不是当前地图的第一个回合才更新
     * On_nmrih_reset_map: 更新 end_time, 并记录新回合
     * 返回字符串, 可用于异步执行. Length = 54 - 4 + float + int
     * min: 70
     *
     * @param sql_str           保存返回的 SQL 字符串
     * @param max_length        SQL 字符串最大长度
     *
     * @return                  No
     */
    public void updRoundEnd_sqlStr(char[] sql_str, int max_length) {
        this.end_time = GetEngineTime();
        FormatEx(sql_str, max_length, "UPDATE round_info SET end_time=%f WHERE id=%d LIMIT 1", this.end_time, this.round_id);
    }
}


void LoadHook_Round()
{
    HookEvent("nmrih_reset_map",            On_nmrih_reset_map,             EventHookMode_Pre);
    HookEvent("nmrih_practice_ending",      On_nmrih_practice_ending,       EventHookMode_Pre);
    HookEvent("nmrih_round_begin",          On_nmrih_round_begin,           EventHookMode_Pre);
    HookEvent("wave_system_begin",          On_wave_system_begin,           EventHookMode_Pre);
    HookEvent("extraction_begin",           On_extraction_begin,            EventHookMode_Pre);     // ! Objective 同样用到
}

NRRound nr_round;


