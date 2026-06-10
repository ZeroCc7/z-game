# 《灵道纪：五行初战》战斗原型设计

## 游戏名称

暂定中文名：`灵道纪：五行初战`

这个名字保留仙侠、修道、五行的气质，但不复用现有游戏的名称、素材、角色、美术、UI 图案或商标元素。

## 目标

基于 Godot 4.6.x 制作一个原创仙侠回合制 RPG 的单场景战斗原型。原型需要有经典国产回合网游战斗的感觉：全屏战场、顶部状态框、右侧竖向指令、底部聊天/战报/快捷栏，以及角色和宠物对战一组妖怪。

第一版用于验证战斗闭环、五行伤害、宠物参战、障碍控制、战报记录、胜负结算和重新挑战流程。

## 不做的内容

- 不做地图探索。
- 不做账号、背包、商城、任务、帮派或联网系统。
- 不做完整宠物养成系统。
- 不做经验、金钱、掉落结算，只显示固定结算摘要。
- 不直接使用现有游戏的名称、UI 素材、角色素材、怪物素材、音频、Logo 或截图作为运行时素材。

## 第一版可玩切片

战斗开始时包含：

- 一个玩家角色。
- 一个宠物。
- 三到五个敌方单位。
- 一个经典回合网游风格的战斗 UI。
- 一组固定技能。
- 可重新开始的胜利/失败弹窗。

玩家每回合为角色和宠物选择行动。敌人自动行动。所有行动按速度排序执行，写入战报，更新气血/法力/状态条，并显示伤害或状态飘字。

## UI 方向

布局采用已经确认的经典回合网游方向：

- 全屏绘制式战场。
- 顶部左侧显示宠物状态框、头像和状态条。
- 顶部右侧显示角色状态框、头像和状态条。
- 中央显示回合文字和大号伤害数字。
- 敌我单位以斜向阵列站在战场中。
- 右侧竖向指令面板。
- 底部聊天/战报区域和快捷图标栏。
- 不显示左侧 `战斗目标` 竖条。

右侧指令面板包含：

- `自动`
- `法术`
- `道具`
- `防御`
- `召唤`
- `召回`
- `保护`
- `捕捉`
- `逃跑`

第一版行为：

- `法术` 打开技能选择。
- `防御` 我方可用。
- `自动` 切换简单自动战斗。
- `道具`、`召唤`、`召回`、`保护`、`捕捉`、`逃跑` 显示固定的 `暂未开放` 提示，不消耗回合。

## 美术方向

第一版美术目标是“原创仙侠 + 经典国产回合网游战斗感”，不追求完全复刻任何现有游戏。美术需要支持 1024x768 战斗画面，优先保证可读性、站位清楚、UI 信息密集但不混乱。

视觉关键词：

- 原创仙侠。
- 五行修行。
- 莲池、水面、荷叶、灵气、古典金色边框。
- 2D 手绘感，略带老网游质感。
- 高对比伤害数字和技能状态文字。

不使用：

- 现有游戏截图作为运行时背景。
- 现有游戏角色、怪物、宠物、UI 框、图标、Logo。
- 直接临摹已有游戏人物造型或界面花纹。

第一版资产清单：

```text
assets/battle/backgrounds/lotus_pond_battle.png
assets/battle/units/hero_qingxuan.png
assets/battle/units/pet_linghu.png
assets/battle/units/enemy_yaobing.png
assets/battle/units/enemy_yaojiang.png
assets/battle/units/enemy_yaowang.png
assets/battle/fx/wood_spell.png
assets/battle/fx/wood_bind.png
assets/battle/fx/heal.png
assets/ui/battle/gold_status_frame.png
assets/ui/battle/command_button.png
assets/ui/battle/quickbar_icons.png
```

美术生产策略：

1. 先生成一张 `lotus_pond_battle.png` 作为战斗背景，要求水面、荷叶、莲花、仙气，但不包含角色、怪物、UI、文字或战斗目标标记。
2. 使用 `$generate2dsprite` 生成角色、宠物和敌方单位的静态或轻量 idle 资产，统一 3/4 顶视战斗视角。
3. 使用 `$generate2dsprite` 生成木系法术、缠绕控制、治疗三个 FX 资产。
4. UI 第一版优先用 Godot 控件绘制金色边框和按钮；如果需要更强质感，再生成 UI 框和按钮贴图。
5. 所有生成提示词保存到 `docs/art/prompts/`，方便后续重做资产。

第一版允许先用程序色块跑通战斗，但最终验收前至少需要替换为原创背景图、我方角色、宠物、三类敌人和三个技能 FX。

## Godot 项目结构

```text
z-game/
  project.godot
  assets/
    battle/
      backgrounds/
      units/
      fx/
    ui/
      battle/
  docs/
    art/
      prompts/
  scenes/
    battle/
      BattleScene.tscn
      BattleScene.gd
      UnitView.tscn
      UnitView.gd
      CommandPanel.tscn
      CommandPanel.gd
      BattleLog.tscn
      BattleLog.gd
  scripts/
    battle/
      BattleController.gd
      BattleState.gd
      BattleUnit.gd
      BattleAction.gd
      BattleResolver.gd
      SkillDatabase.gd
      ElementRules.gd
  data/
    skills.json
    units.json
```

职责划分：

- `BattleScene`：连接战场、单位视图、指令面板、战报和结算弹窗。
- `BattleController`：负责回合流程、玩家输入状态、敌人 AI 和回合推进。
- `BattleState`：保存单位、回合数、行动队列和战斗结果。
- `BattleUnit`：玩家、宠物、敌人的统一数据模型。
- `BattleAction`：描述一次待执行行动和目标。
- `BattleResolver`：计算伤害、治疗、控制命中、防御、死亡和战报事件。
- `ElementRules`：计算五行关系和伤害修正。
- `SkillDatabase`：从 `data/skills.json` 读取技能定义。
- `UnitView`、`CommandPanel`、`BattleLog`：只负责显示和交互，不写战斗数学。

## 单位模型

每个单位包含：

```text
id
name
side: player | pet | enemy
element: metal | wood | water | fire | earth
max_hp
hp
max_mp
mp
attack
defense
magic
speed
dao
resist_control
status_effects
is_defending
```

## 五行规则

克制关系：

```text
金克木
木克土
土克水
水克火
火克金
```

伤害修正：

- 攻击方克制目标：伤害 `+20%`
- 目标克制攻击方：伤害 `-10%`
- 无克制关系：不修正
- 治疗不受五行关系影响

## 技能类型

- `attack`：普通物理攻击。
- `element_damage`：消耗法力的五行法术。
- `control`：障碍/控制技能，使目标跳过下一次行动。
- `heal`：恢复我方气血。
- `defend`：我方本回合减伤。
- `pet_attack`：宠物普通攻击。
- `pet_skill`：宠物简单法术。

技能示例：

```json
{
  "id": "wood_bind",
  "name": "青藤缠",
  "type": "control",
  "element": "wood",
  "mp_cost": 18,
  "base_chance": 0.55,
  "duration": 1
}
```

## 障碍控制公式

```text
命中率 = 基础命中 + (施法者道行 - 目标道行) * 0.003 - 目标控制抗性
```

最终命中率限制在 `20%` 到 `85%` 之间。

控制成功后，目标获得一回合控制状态，并在下一次可行动时跳过行动。

## 回合流程

1. 显示 `第 N 回合`。
2. 玩家选择角色行动。
3. 玩家选择宠物行动，或宠物默认攻击当前目标。
4. 敌人 AI 生成行动。
5. 所有有效行动按 `speed` 从高到低排序。
6. 逐个执行行动。
7. 死亡或被控制的单位轮到行动时跳过。
8. 应用伤害、治疗、控制和防御效果。
9. 添加底部战报，并显示飘字反馈。
10. 检查胜利或失败。
11. 进入下一回合。

## 敌人 AI

敌人不使用防御。

普通敌人行为：

- 通常攻击玩家角色。
- 偶尔攻击宠物。

精英和首领行为：

- 可以普通攻击。
- 可以偶尔施放五行法术。
- 首领可以偶尔施放障碍控制技能。

难度来自敌人的气血、防御、法术、道行、控制抗性和敌方数量，而不是通过防御拖慢节奏。

建议敌方数值：

```text
普通妖兵
hp: 420
attack: 52
defense: 24
magic: 18
speed: 38
dao: 80
resist_control: 0.05

精英妖将
hp: 760
attack: 68
defense: 38
magic: 36
speed: 42
dao: 130
resist_control: 0.12

首领妖王
hp: 1280
attack: 82
defense: 52
magic: 58
speed: 35
dao: 180
resist_control: 0.18
```

建议我方数值：

```text
角色
hp: 980
mp: 220
attack: 70
defense: 42
magic: 72
speed: 48
dao: 160

宠物
hp: 720
attack: 86
defense: 30
magic: 28
speed: 55
dao: 60
```

## 目标选择规则

- 伤害和控制技能选择敌方目标。
- 治疗技能选择我方目标。
- 防御技能只作用于自己。
- 目标不合法时，底部提示错误，不推进回合。
- 自动战斗如果没有目标，则默认选择第一个存活敌人。

## 视觉反馈

- 黄色飘字表示伤害。
- 绿色飘字表示治疗。
- 控制成功显示短状态文字，例如 `缠绕`。
- 死亡单位变暗或隐藏。
- 底部战报用中文记录每次行动结果。

## 结算

胜利：

- 敌方全部倒下时触发。
- 显示 `战斗胜利`。
- 包含 `再战一场` 按钮。
- 只显示固定结算摘要。

失败：

- 玩家角色倒下时触发。
- 宠物倒下不会直接失败。
- 显示 `战斗失败`。
- 包含 `重新挑战` 按钮。

重新挑战会重置所有单位、回合数、战报、状态和指令状态。

## 验证标准

实现完成时必须满足：

1. Godot 能打开主战斗场景。
2. UI 使用已确认的经典回合网游布局方向。
3. UI 不包含 `战斗目标` 竖条。
4. 战斗背景、角色、宠物、敌人和技能 FX 使用原创资产。
5. `法术` 能打开技能选择流程。
6. 角色和宠物能在同一回合各行动一次。
7. 敌人不会防御。
8. 五行克制关系会影响伤害。
9. 障碍控制能让目标跳过下一次行动。
10. 目标不合法时显示提示，并且不消耗回合。
11. 底部战报能准确记录行动。
12. 胜利和失败结算弹窗都能出现。
13. 重新挑战能干净重置战斗。
14. 运行时素材和命名保持原创，不复用现有游戏 IP。
