# NMRIH Record System

仅适用于 No More Room In Hell !!!

可用于记录玩家的游戏数据，能够区分每个玩家，在每个地图的每一个回合上的游玩数据。

包括该回合的任务路线、每个任务信息、实际耗时、输出伤害、受到伤害，以及玩家的统计数据，历史以来游玩时长、撤离数、击杀数等。

## Requirements

- [SourceMod 1.11](https://www.sourcemod.net/downloads.php?branch=stable) or higher

- [multicolors](https://github.com/Bara/Multi-Colors)

- [smlib/crypt - Crypt_MD5(part)](https://github.com/bcserv/smlib/tree/transitional_syntax)

- [nmo-guard - gamedata & objective-manager.sp(have modification)](https://github.com/dysphie/nmo-guard)

- MySQL 5.7 or higher



## Installation
- To create a new database in your MySQL, use [./sql/create_table.sql](./sql/create_table.sql) to create tables for the database (on the safe side, please create a separate user for the database)
- Edit `addons/sourcemod/configs/databases.cfg`, add a named `nmrih_record` configuration, connection of the newly created database
- Grab the latest ZIP from releases
- Extract the contents into `addons/sourcemod`
- restart server or change map


代码架构：类似于 "工厂" 的模式，每个 "工厂" 负责各自的职责，由 "客户"（或连接器）在相应情况下找工厂实现相应需求。

客户（连接器）：`./scripting/nmrih-record.sp`

目前已有有多个 "工厂"：`./scripting/nmrih-record/*`

- dbi：连接数据库，预编译、执行、执行+获取插入id、处理数据库/预编译/SQL报错
- map：记录地图开始、结束
- round：记录地图的每一个回合信息
- objective：记录回合的每一个任务信息
- player：记录玩家的游戏数据，每回合的统计数据存放在 `round_data` 中
- printer：输出提示信息
- menu：插件菜单。待开发...
- manager：监听一些特殊但与游戏数据关系不大的事件，帮助管理员更好的处理玩家纠纷（会占用一定的性能）
- debugger：调试模式（暂时弃用）

