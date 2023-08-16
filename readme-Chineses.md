# NMRIH Record System

**文档 :** [中文](./readme-Chineses.md)

记录玩家的游戏数据，能够区分每个玩家，在每个地图的每一个回合上的游玩数据。

包括该回合的任务路线、每个任务信息、实际耗时、输出伤害、受到伤害，以及玩家的统计数据，历史以来游玩时长、撤离数、击杀数等。



## 指令

|            指令            |                      描述                      |
| :------------------------: | :--------------------------------------------: |
|    !top 或 !rank 或 !wr    |  打开目录菜单，可选查看撤离榜单、设置客户偏好  |
| !top10 或 !rank10 或 !wr10 | 在聊天框输出当前地图的当前回合的最快撤离 Top10 |



## 参数

|      插件信息参数       |    描述    |
| :-----------------------------: | :---------: |
| sm_nr_version | 插件版本号 |

|     配置参数     |    默认值    |                        描述                         |
| :-----------------------------: | :---------: | :----------------------------------------------------------: |
| sm_nr_dbi_config | nmrih_record | 数据库连接的参数（sourcemod/configs/databases.cfg） |

|           定时器参数            | 默认值 |                             描述                             |
| :-----------------------------: | :----: | :----------------------------------------------------------: |
|   sm_nr_global_timer_interval   |  60.0  | 全局定时器每隔多少秒执行一次<br>（工厂内部也有一个参数用于控制最短执行间隔） |
|      sm_nr_dbi_keep_alive       |   1    | 是否保持数据库长连接<br>（每隔一段时间检查连接可用性，建议开启） |
|  sm_nr_dbi_keep_alive_interval  | 900.0  |          最少间隔多少秒后检查一次数据库连接是否正常          |
| sm_nr_player_play_time_interval |  60.0  |              最少间隔多少秒更新一次玩家游玩时长              |

|          游戏内提示信息参数          |  默认值   |                             描述                             |
| :-----------------------------: | :---------: | :----------------------------------------------------------: |
|     sm_nr_printer_show_play_time     |     0     |          是否在玩家加入时, 输出来源、在本服游玩时长          |
|  sm_nr_printer_delay_show_play_time  | 5.0 | 玩家加入多少秒后输出、记录数据<br>（sm_nr_printer_show_play_time = 0 也会记录，但不会在聊天框输出提示信息） |
|  sm_nr_printer_show_extraction_time  |     0     |        是否在回合开始时, 输出本回合最短/平均撤离耗时         |
|   sm_nr_printer_show_obj_chain_md5   |     0     | 是否在回合开始时, 输出本回合任务链的 MD5 Hash 值 <br>（可用于区分不同路线） |
|     sm_nr_printer_show_obj_start     |     0     |              是否在新任务开始时, 输出该任务信息              |
|     sm_nr_printer_show_wave_max      |     0     |           是否在回合开始时, 输出本回合最大 wave 数           |
|    sm_nr_printer_show_wave_start     |     0     |              是否在新wave开始时, 输出该wave信息              |
| sm_nr_printer_show_extraction_begin  |     0     |                是否在撤离开始时, 输出相关信息                |
| sm_nr_printer_show_player_extraction |     0     |                     是否输出玩家撤离成功                     |
| sm_nr_printer_show_watermelon_rescue |     0     |              是否在西瓜救援成功时, 输出相关信息              |
| sm_nr_printer_spawn_tolerance | 10.0 | round_begin 后这么多秒内复活的玩家在计算通关时长时将被罚时 |
| sm_nr_printer_spawn_penalty_factor | 0.25 | 额外罚时百分比. 最终结果 = (撤离时间 - round_begin) * (1.0 + value) |

|          菜单参数          |  默认值   |                             描述                             |
| :-----------------------------: | :---------: | :----------------------------------------------------------: |
|     sm_nr_menu_top_enabled     |     0     |          是否启用数据榜单菜单          |



## 依赖

- 仅适用于 ==No More Room In Hell==

- clientprefs 插件拓展

- [SourceMod 1.12](https://www.sourcemod.net/downloads.php?branch=stable) 或更高版本

- [multicolors](https://github.com/Bara/Multi-Colors)

- [smlib/crypt - [Crypt_MD5(part)]](https://github.com/bcserv/smlib/tree/transitional_syntax)

- [nmo-guard - [gamedata & objective-manager.sp]](https://github.com/dysphie/nmo-guard)

- MySQL 5.7 或更高版本



## 安装教程
- 在 MySQL 中为你的服务器创建一个数据库，名字必须与 Convar `nmrih_record` 的值相同；
- 使用 [./sql/create_table_main.sql](./sql/create_table_main.sql) 创建核心数据表；
- 如果编译时定义了 `INCLUDE_MANAGER`，则还需要使用 [./sql/create_table_manager.sql](./sql/create_table_manager.sql) 创建相关数据表；
- 如果查询业务偏多（ printer、menu 参数都为 1 ），建议使用 [create_table_index_main.sql](./sql/create_table_index_main.sql) 为核心表创建索引，提高查询效率；
- 编辑 `addons/sourcemod/configs/databases.cfg`, 添加一个名称与 `nmrih_record` 的值相同的配置（用于配置连接到数据库的参数）
- 下载最新发行版压缩包
- 解压到 `addons/sourcemod`
- 重启服务器（插件不支持中途加载，可能导致数据不准确）



### 代码思想：

类似于 "工厂" 的模式，每个 "工厂" 负责各自的职责，由 "客户"（或连接器）在相应情况下交给工厂实现相应需求。

与数据库交互的需求一般会使用异步的方式执行，避免游戏主线程等待。目前新增地图数据，新增回合仍是同步，其他都为异步。

客户（连接器）：`./scripting/nmrih-record.sp`

目前已有有多个 "工厂"：`./scripting/nmrih-record/*`

- dbi：连接数据库，预编译、执行、执行+获取插入id、处理数据库/预编译/SQL报错
- map：记录地图开始、结束
- round：记录地图的每一个回合信息
- objective：记录回合的每一个任务信息
- player：记录玩家的游戏数据，每回合的统计数据存放在 `round_data` 中
- printer：输出提示信息
- menu：提供数据查看菜单、客户偏好菜单
- manager：监听一些可用于特殊纠纷管理但与回合数据关系不大的事件，帮助管理员更好的处理玩家纠纷（会占用少量的资源）

