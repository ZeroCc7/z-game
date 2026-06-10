# 灵道纪五行初战战斗原型 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建一个 Godot 4.6.x 单场景原创仙侠回合制战斗原型，完成角色+宠物对战多名敌人的经典国产回合网游式战斗闭环。

**Architecture:** 规则层和表现层分离：`scripts/battle/` 只负责数据、五行、技能、回合和结算；`scenes/battle/` 只负责 Godot UI、单位显示和玩家交互。测试先覆盖规则层，再接入场景。

**Tech Stack:** Godot 4.6.x、GDScript、JSON 配置、Godot headless 脚本测试。

---

## 文件结构

创建以下文件：

```text
project.godot
assets/battle/backgrounds/.gitkeep
assets/battle/units/.gitkeep
assets/battle/fx/.gitkeep
assets/ui/battle/.gitkeep
data/skills.json
data/units.json
docs/art/prompts/battle-background.md
docs/art/prompts/battle-units.md
docs/art/prompts/battle-fx.md
scripts/battle/ElementRules.gd
scripts/battle/BattleUnit.gd
scripts/battle/BattleAction.gd
scripts/battle/SkillDatabase.gd
scripts/battle/BattleState.gd
scripts/battle/BattleResolver.gd
scripts/battle/BattleController.gd
scenes/battle/BattleScene.tscn
scenes/battle/BattleScene.gd
scenes/battle/UnitView.tscn
scenes/battle/UnitView.gd
scenes/battle/CommandPanel.tscn
scenes/battle/CommandPanel.gd
scenes/battle/BattleLog.tscn
scenes/battle/BattleLog.gd
tests/battle/BattleRuleTests.gd
tests/run_battle_tests.gd
```

核心边界：

- `ElementRules.gd`：五行克制和伤害倍率。
- `BattleUnit.gd`：战斗单位数据与状态方法。
- `BattleAction.gd`：一次行动的结构。
- `SkillDatabase.gd`：技能 JSON 加载和查询。
- `BattleState.gd`：当前战斗状态。
- `BattleResolver.gd`：执行单个行动。
- `BattleController.gd`：组织整回合流程、敌人 AI、自动战斗和胜负。
- `BattleScene.gd`：连接 UI 和 `BattleController`。

---

### Task 0: 美术方向和资产生产准备

**Files:**
- Create: `assets/battle/backgrounds/.gitkeep`
- Create: `assets/battle/units/.gitkeep`
- Create: `assets/battle/fx/.gitkeep`
- Create: `assets/ui/battle/.gitkeep`
- Create: `docs/art/prompts/battle-background.md`
- Create: `docs/art/prompts/battle-units.md`
- Create: `docs/art/prompts/battle-fx.md`

- [ ] **Step 1: 创建资产目录**

Run:

```powershell
New-Item -ItemType Directory -Force -Path assets/battle/backgrounds, assets/battle/units, assets/battle/fx, assets/ui/battle, docs/art/prompts
New-Item -ItemType File -Force -Path assets/battle/backgrounds/.gitkeep, assets/battle/units/.gitkeep, assets/battle/fx/.gitkeep, assets/ui/battle/.gitkeep
```

Expected:

```text
资产目录存在，Godot 后续可通过 res://assets/... 引用。
```

- [ ] **Step 2: 写背景图生成提示词**

写入 `docs/art/prompts/battle-background.md`：

````markdown
# 战斗背景提示词

目标文件：`assets/battle/backgrounds/lotus_pond_battle.png`

用途：Godot 1024x768 战斗场景背景。

提示词：

```text
原创仙侠回合制 RPG 战斗背景，1024x768 横向画面，3/4 顶视视角，清澈蓝绿色水面，大片荷叶和莲花，远处有石莲台和淡淡仙气，适合角色和怪物站在画面两侧对战。画面中不要出现角色、怪物、UI、文字、按钮、伤害数字、战斗目标标记或任何现有游戏元素。风格为 2D 手绘游戏背景，略带经典国产回合网游质感，色彩清晰，战斗单位放上去后仍然容易阅读。
```

验收：

- 没有文字和 UI。
- 没有角色或怪物。
- 左侧和右下方有足够空间放单位。
- 画面读起来像仙侠战斗场景。
````

- [ ] **Step 3: 写单位资产生成提示词**

写入 `docs/art/prompts/battle-units.md`：

````markdown
# 战斗单位提示词

统一要求：

- 原创角色，不使用现有游戏 IP。
- 3/4 顶视战斗视角。
- 透明背景 PNG。
- 适合放在 1024x768 回合制战斗场景里。
- 不要文字、UI、血条、光标或伤害数字。

## 角色：青玄

目标文件：`assets/battle/units/hero_qingxuan.png`

```text
原创仙侠男主角，名为青玄，木系修行者，青白长袍，腰间玉佩，手持细长法剑，3/4 顶视回合制战斗站姿，轻微施法姿态，透明背景，2D 手绘游戏角色，经典国产回合网游质感，不要文字，不要 UI，不要现有游戏元素。
```

## 宠物：灵狐

目标文件：`assets/battle/units/pet_linghu.png`

```text
原创仙侠灵狐宠物，白色和淡金色毛发，三条小尾巴，额头有火焰灵纹，3/4 顶视回合制战斗站姿，体型小于角色，透明背景，2D 手绘游戏宠物，经典国产回合网游质感，不要文字，不要 UI，不要现有游戏元素。
```

## 普通妖兵

目标文件：`assets/battle/units/enemy_yaobing.png`

```text
原创妖兵怪物，水泽妖怪士兵，暗青盔甲，弯角头盔，手持短戟，3/4 顶视回合制战斗站姿，可重复摆放为小怪队列，透明背景，2D 手绘游戏怪物，经典国产回合网游质感，不要文字，不要 UI，不要现有游戏元素。
```

## 精英妖将

目标文件：`assets/battle/units/enemy_yaojiang.png`

```text
原创精英妖将，水泽妖怪将领，重甲，肩甲更大，武器为长柄战斧，体型比普通妖兵更高，3/4 顶视回合制战斗站姿，透明背景，2D 手绘游戏怪物，经典国产回合网游质感，不要文字，不要 UI，不要现有游戏元素。
```

## 首领妖王

目标文件：`assets/battle/units/enemy_yaowang.png`

```text
原创首领妖王，莲池深处的火木双相妖王，高大威严，暗红和墨绿色妖气，头戴破碎王冠，3/4 顶视回合制战斗站姿，透明背景，2D 手绘游戏 Boss，经典国产回合网游质感，不要文字，不要 UI，不要现有游戏元素。
```
````

- [ ] **Step 4: 写技能 FX 生成提示词**

写入 `docs/art/prompts/battle-fx.md`：

````markdown
# 战斗技能 FX 提示词

统一要求：

- 原创仙侠五行法术效果。
- 透明背景 PNG。
- 不要文字、UI、按钮、角色或怪物。
- 适合叠加在 Godot 2D 战斗单位上方。

## 青木诀

目标文件：`assets/battle/fx/wood_spell.png`

```text
原创木系仙法攻击特效，青绿色灵气形成旋转藤叶和小型木刺，适合命中单个敌人，透明背景，2D 手绘游戏 FX，经典国产回合网游质感，不要文字，不要 UI，不要角色。
```

## 青藤缠

目标文件：`assets/battle/fx/wood_bind.png`

```text
原创障碍控制特效，青绿色藤蔓从地面缠绕目标，带少量灵光符纹，透明背景，2D 手绘游戏 FX，经典国产回合网游质感，不要文字，不要 UI，不要角色。
```

## 回春术

目标文件：`assets/battle/fx/heal.png`

```text
原创治疗特效，柔和绿色光环、叶片和上升灵气粒子，适合恢复我方单位气血，透明背景，2D 手绘游戏 FX，经典国产回合网游质感，不要文字，不要 UI，不要角色。
```
````

- [ ] **Step 5: 生成资产**

执行方式：

```text
重启 Codex 后使用 $generate2dmap 生成 lotus_pond_battle.png。
重启 Codex 后使用 $generate2dsprite 生成角色、宠物、敌人和三个 FX。
```

产物必须保存到：

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
```

如果当前 Codex 会话还没加载新安装的 skills，先用程序色块完成规则和 UI；不要把现有游戏截图或素材放进运行时。

---

### Task 1: 创建 Godot 项目骨架

**Files:**
- Create: `project.godot`
- Create: `scenes/battle/BattleScene.tscn`
- Create: `scenes/battle/BattleScene.gd`

- [ ] **Step 1: 创建最小 Godot 项目配置**

写入 `project.godot`：

```ini
; Engine configuration file.
; Godot 4.x project.

config_version=5

[application]
config/name="灵道纪：五行初战"
run/main_scene="res://scenes/battle/BattleScene.tscn"
config/features=PackedStringArray("4.6")

[display]
window/size/viewport_width=1024
window/size/viewport_height=768
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

- [ ] **Step 2: 创建主战斗场景**

写入 `scenes/battle/BattleScene.tscn`：

```ini
[gd_scene load_steps=2 format=3 uid="uid://battle_scene"]

[ext_resource type="Script" path="res://scenes/battle/BattleScene.gd" id="1"]

[node name="BattleScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
```

- [ ] **Step 3: 创建主场景脚本占位并能运行**

写入 `scenes/battle/BattleScene.gd`：

```gdscript
extends Control

func _ready() -> void:
	print("灵道纪：五行初战 battle scene loaded")
```

- [ ] **Step 4: 验证项目能被 Godot 识别**

Run:

```powershell
godot --headless --path . --quit
```

Expected:

```text
Godot Engine v4.6
```

并且没有 `Project file not found` 或场景加载错误。

---

### Task 2: 建立五行规则和规则测试入口

**Files:**
- Create: `scripts/battle/ElementRules.gd`
- Create: `tests/battle/BattleRuleTests.gd`
- Create: `tests/run_battle_tests.gd`

- [ ] **Step 1: 先写五行测试**

写入 `tests/battle/BattleRuleTests.gd`：

```gdscript
extends RefCounted

const ElementRules = preload("res://scripts/battle/ElementRules.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_assert_equal(ElementRules.get_modifier("metal", "wood"), 1.2, "金克木应为 1.2", failures)
	_assert_equal(ElementRules.get_modifier("wood", "metal"), 0.9, "木被金克应为 0.9", failures)
	_assert_equal(ElementRules.get_modifier("water", "earth"), 0.9, "水被土克应为 0.9", failures)
	_assert_equal(ElementRules.get_modifier("fire", "water"), 0.9, "火被水克应为 0.9", failures)
	_assert_equal(ElementRules.get_modifier("earth", "fire"), 1.0, "土与火无直接克制应为 1.0", failures)
	return failures

func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s: expected=%s actual=%s" % [message, str(expected), str(actual)])
```

- [ ] **Step 2: 写测试运行器**

写入 `tests/run_battle_tests.gd`：

```gdscript
extends SceneTree

const BattleRuleTests = preload("res://tests/battle/BattleRuleTests.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	failures.append_array(BattleRuleTests.new().run())
	if failures.is_empty():
		print("Battle tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

- [ ] **Step 3: 运行测试并确认失败**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Could not resolve script "res://scripts/battle/ElementRules.gd"
```

- [ ] **Step 4: 实现五行规则**

写入 `scripts/battle/ElementRules.gd`：

```gdscript
class_name ElementRules
extends RefCounted

const COUNTERS := {
	"metal": "wood",
	"wood": "earth",
	"earth": "water",
	"water": "fire",
	"fire": "metal",
}

static func get_modifier(attacker_element: String, target_element: String) -> float:
	if COUNTERS.get(attacker_element, "") == target_element:
		return 1.2
	if COUNTERS.get(target_element, "") == attacker_element:
		return 0.9
	return 1.0
```

- [ ] **Step 5: 运行测试并确认通过**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Battle tests passed
```

---

### Task 3: 创建单位、行动和配置数据

**Files:**
- Create: `scripts/battle/BattleUnit.gd`
- Create: `scripts/battle/BattleAction.gd`
- Create: `data/skills.json`
- Create: `data/units.json`
- Modify: `tests/battle/BattleRuleTests.gd`

- [ ] **Step 1: 增加单位状态测试**

在 `tests/battle/BattleRuleTests.gd` 顶部加入：

```gdscript
const BattleUnit = preload("res://scripts/battle/BattleUnit.gd")
```

在 `run()` 中 `return failures` 前加入：

```gdscript
	var unit := BattleUnit.from_dict({
		"id": "hero",
		"name": "青玄",
		"side": "player",
		"element": "wood",
		"max_hp": 100,
		"hp": 100,
		"max_mp": 50,
		"mp": 50,
		"attack": 20,
		"defense": 5,
		"magic": 30,
		"speed": 10,
		"dao": 100,
		"resist_control": 0.1
	})
	unit.apply_damage(35)
	_assert_equal(unit.hp, 65, "单位扣血应正确", failures)
	unit.heal(20)
	_assert_equal(unit.hp, 85, "单位治疗应正确", failures)
	unit.heal(50)
	_assert_equal(unit.hp, 100, "治疗不能超过最大气血", failures)
	_assert_equal(unit.is_alive(), true, "气血大于 0 时应存活", failures)
	unit.apply_damage(120)
	_assert_equal(unit.is_alive(), false, "气血为 0 时应死亡", failures)
```

- [ ] **Step 2: 实现战斗单位模型**

写入 `scripts/battle/BattleUnit.gd`：

```gdscript
class_name BattleUnit
extends RefCounted

var id: String
var display_name: String
var side: String
var element: String
var max_hp: int
var hp: int
var max_mp: int
var mp: int
var attack: int
var defense: int
var magic: int
var speed: int
var dao: int
var resist_control: float
var status_effects: Array[Dictionary] = []
var is_defending := false

static func from_dict(data: Dictionary) -> BattleUnit:
	var unit := BattleUnit.new()
	unit.id = data.get("id", "")
	unit.display_name = data.get("name", "")
	unit.side = data.get("side", "")
	unit.element = data.get("element", "")
	unit.max_hp = int(data.get("max_hp", data.get("hp", 1)))
	unit.hp = int(data.get("hp", unit.max_hp))
	unit.max_mp = int(data.get("max_mp", data.get("mp", 0)))
	unit.mp = int(data.get("mp", unit.max_mp))
	unit.attack = int(data.get("attack", 1))
	unit.defense = int(data.get("defense", 0))
	unit.magic = int(data.get("magic", 0))
	unit.speed = int(data.get("speed", 1))
	unit.dao = int(data.get("dao", 0))
	unit.resist_control = float(data.get("resist_control", 0.0))
	return unit

func is_alive() -> bool:
	return hp > 0

func apply_damage(amount: int) -> int:
	var actual := max(amount, 0)
	hp = max(hp - actual, 0)
	return actual

func heal(amount: int) -> int:
	var before := hp
	hp = min(hp + max(amount, 0), max_hp)
	return hp - before

func spend_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	return true

func has_status(status_id: String) -> bool:
	for status in status_effects:
		if status.get("id", "") == status_id:
			return true
	return false

func add_status(status_id: String, duration: int) -> void:
	status_effects.append({"id": status_id, "duration": duration})

func consume_control_if_present() -> bool:
	for index in range(status_effects.size()):
		if status_effects[index].get("id", "") == "controlled":
			status_effects.remove_at(index)
			return true
	return false
```

- [ ] **Step 3: 创建行动模型**

写入 `scripts/battle/BattleAction.gd`：

```gdscript
class_name BattleAction
extends RefCounted

var actor_id: String
var target_id: String
var skill_id: String
var action_type: String

static func make(actor_id_value: String, target_id_value: String, skill_id_value: String, type_value: String) -> BattleAction:
	var action := BattleAction.new()
	action.actor_id = actor_id_value
	action.target_id = target_id_value
	action.skill_id = skill_id_value
	action.action_type = type_value
	return action
```

- [ ] **Step 4: 创建技能配置**

写入 `data/skills.json`：

```json
[
  {
    "id": "attack",
    "name": "普攻",
    "type": "attack",
    "mp_cost": 0,
    "power": 1.0
  },
  {
    "id": "wood_spell",
    "name": "青木诀",
    "type": "element_damage",
    "element": "wood",
    "mp_cost": 22,
    "power": 1.35
  },
  {
    "id": "wood_bind",
    "name": "青藤缠",
    "type": "control",
    "element": "wood",
    "mp_cost": 18,
    "base_chance": 0.55,
    "duration": 1
  },
  {
    "id": "spring_heal",
    "name": "回春术",
    "type": "heal",
    "element": "wood",
    "mp_cost": 24,
    "power": 1.2
  },
  {
    "id": "pet_claw",
    "name": "灵爪",
    "type": "pet_attack",
    "mp_cost": 0,
    "power": 1.1
  },
  {
    "id": "boss_fire",
    "name": "妖火咒",
    "type": "element_damage",
    "element": "fire",
    "mp_cost": 0,
    "power": 1.15
  },
  {
    "id": "boss_bind",
    "name": "妖藤锁",
    "type": "control",
    "element": "wood",
    "mp_cost": 0,
    "base_chance": 0.42,
    "duration": 1
  }
]
```

- [ ] **Step 5: 创建单位配置**

写入 `data/units.json`：

```json
[
  {
    "id": "hero",
    "name": "青玄",
    "side": "player",
    "element": "wood",
    "hp": 980,
    "mp": 220,
    "attack": 70,
    "defense": 42,
    "magic": 72,
    "speed": 48,
    "dao": 160,
    "resist_control": 0.08
  },
  {
    "id": "pet",
    "name": "灵狐",
    "side": "pet",
    "element": "fire",
    "hp": 720,
    "mp": 80,
    "attack": 86,
    "defense": 30,
    "magic": 28,
    "speed": 55,
    "dao": 60,
    "resist_control": 0.04
  },
  {
    "id": "enemy_1",
    "name": "普通妖兵",
    "side": "enemy",
    "element": "earth",
    "hp": 420,
    "mp": 0,
    "attack": 52,
    "defense": 24,
    "magic": 18,
    "speed": 38,
    "dao": 80,
    "resist_control": 0.05
  },
  {
    "id": "enemy_2",
    "name": "普通妖兵",
    "side": "enemy",
    "element": "water",
    "hp": 420,
    "mp": 0,
    "attack": 52,
    "defense": 24,
    "magic": 18,
    "speed": 38,
    "dao": 80,
    "resist_control": 0.05
  },
  {
    "id": "enemy_3",
    "name": "精英妖将",
    "side": "enemy",
    "element": "metal",
    "hp": 760,
    "mp": 0,
    "attack": 68,
    "defense": 38,
    "magic": 36,
    "speed": 42,
    "dao": 130,
    "resist_control": 0.12
  },
  {
    "id": "enemy_boss",
    "name": "首领妖王",
    "side": "enemy",
    "element": "fire",
    "hp": 1280,
    "mp": 0,
    "attack": 82,
    "defense": 52,
    "magic": 58,
    "speed": 35,
    "dao": 180,
    "resist_control": 0.18
  }
]
```

- [ ] **Step 6: 运行测试**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Battle tests passed
```

---

### Task 4: 实现技能加载和战斗状态

**Files:**
- Create: `scripts/battle/SkillDatabase.gd`
- Create: `scripts/battle/BattleState.gd`
- Modify: `tests/battle/BattleRuleTests.gd`

- [ ] **Step 1: 增加配置加载测试**

在 `tests/battle/BattleRuleTests.gd` 顶部加入：

```gdscript
const SkillDatabase = preload("res://scripts/battle/SkillDatabase.gd")
const BattleState = preload("res://scripts/battle/BattleState.gd")
```

在 `run()` 中 `return failures` 前加入：

```gdscript
	var skills := SkillDatabase.new()
	var load_result := skills.load_from_path("res://data/skills.json")
	_assert_equal(load_result, true, "技能配置应能加载", failures)
	_assert_equal(skills.get_skill("wood_bind").get("name", ""), "青藤缠", "应能按 id 查询技能", failures)

	var state := BattleState.new()
	state.load_units_from_path("res://data/units.json")
	_assert_equal(state.get_unit("hero").display_name, "青玄", "应能加载角色", failures)
	_assert_equal(state.get_living_enemies().size(), 4, "应加载四个敌人", failures)
```

- [ ] **Step 2: 实现技能数据库**

写入 `scripts/battle/SkillDatabase.gd`：

```gdscript
class_name SkillDatabase
extends RefCounted

var skills_by_id: Dictionary = {}

func load_from_path(path: String) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return false
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			skills_by_id[item["id"]] = item
	return true

func get_skill(skill_id: String) -> Dictionary:
	return skills_by_id.get(skill_id, {})

func get_player_skills() -> Array[Dictionary]:
	return [
		get_skill("wood_spell"),
		get_skill("wood_bind"),
		get_skill("spring_heal"),
	]
```

- [ ] **Step 3: 实现战斗状态**

写入 `scripts/battle/BattleState.gd`：

```gdscript
class_name BattleState
extends RefCounted

const BattleUnit = preload("res://scripts/battle/BattleUnit.gd")

var round_number := 1
var units: Array[BattleUnit] = []
var battle_result := ""
var log_lines: Array[String] = []

func load_units_from_path(path: String) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return false
	units.clear()
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			units.append(BattleUnit.from_dict(item))
	return true

func get_unit(unit_id: String) -> BattleUnit:
	for unit in units:
		if unit.id == unit_id:
			return unit
	return null

func get_living_enemies() -> Array[BattleUnit]:
	return units.filter(func(unit: BattleUnit) -> bool: return unit.side == "enemy" and unit.is_alive())

func get_living_allies() -> Array[BattleUnit]:
	return units.filter(func(unit: BattleUnit) -> bool: return unit.side != "enemy" and unit.is_alive())

func add_log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 8:
		log_lines.pop_front()

func check_result() -> String:
	if get_living_enemies().is_empty():
		battle_result = "victory"
	elif get_unit("hero") == null or not get_unit("hero").is_alive():
		battle_result = "failure"
	return battle_result
```

- [ ] **Step 4: 运行测试**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Battle tests passed
```

---

### Task 5: 实现行动结算

**Files:**
- Create: `scripts/battle/BattleResolver.gd`
- Modify: `tests/battle/BattleRuleTests.gd`

- [ ] **Step 1: 增加伤害、治疗、控制测试**

在 `tests/battle/BattleRuleTests.gd` 顶部加入：

```gdscript
const BattleResolver = preload("res://scripts/battle/BattleResolver.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")
```

在 `run()` 中 `return failures` 前加入：

```gdscript
	var resolver_state := BattleState.new()
	resolver_state.load_units_from_path("res://data/units.json")
	var resolver_skills := SkillDatabase.new()
	resolver_skills.load_from_path("res://data/skills.json")
	var resolver := BattleResolver.new(resolver_state, resolver_skills)
	var enemy := resolver_state.get_unit("enemy_1")
	var old_hp := enemy.hp
	var damage_event := resolver.resolve(BattleAction.make("hero", "enemy_1", "wood_spell", "element_damage"))
	_assert_equal(damage_event.get("type", ""), "damage", "五行法术应造成伤害", failures)
	if enemy.hp >= old_hp:
		failures.append("五行法术后敌人气血应下降")

	var hero := resolver_state.get_unit("hero")
	hero.apply_damage(200)
	var damaged_hp := hero.hp
	var heal_event := resolver.resolve(BattleAction.make("hero", "hero", "spring_heal", "heal"))
	_assert_equal(heal_event.get("type", ""), "heal", "治疗应返回 heal 事件", failures)
	if hero.hp <= damaged_hp:
		failures.append("治疗后角色气血应上升")

	var control_target := resolver_state.get_unit("enemy_2")
	var control_event := resolver.resolve(BattleAction.make("hero", "enemy_2", "wood_bind", "control"))
	_assert_equal(control_event.has("success"), true, "控制事件应包含 success 字段", failures)
	if control_event.get("success", false) and not control_target.has_status("controlled"):
		failures.append("控制成功后目标应有 controlled 状态")
```

- [ ] **Step 2: 实现行动结算器**

写入 `scripts/battle/BattleResolver.gd`：

```gdscript
class_name BattleResolver
extends RefCounted

const ElementRules = preload("res://scripts/battle/ElementRules.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")

var state
var skills
var rng := RandomNumberGenerator.new()

func _init(state_value, skills_value) -> void:
	state = state_value
	skills = skills_value
	rng.seed = 12345

func resolve(action: BattleAction) -> Dictionary:
	var actor = state.get_unit(action.actor_id)
	var target = state.get_unit(action.target_id)
	var skill: Dictionary = skills.get_skill(action.skill_id)
	if actor == null or target == null or not actor.is_alive():
		return {"type": "invalid", "message": "行动无效"}
	if target.consume_control_if_present():
		var skip_line := "%s 被障碍控制，跳过行动。" % actor.display_name
		state.add_log(skip_line)
		return {"type": "skip", "message": skip_line}
	match skill.get("type", action.action_type):
		"attack", "pet_attack":
			return _resolve_attack(actor, target, skill)
		"element_damage":
			return _resolve_element_damage(actor, target, skill)
		"heal":
			return _resolve_heal(actor, target, skill)
		"control":
			return _resolve_control(actor, target, skill)
		"defend":
			actor.is_defending = true
			state.add_log("%s 进入防御姿态。" % actor.display_name)
			return {"type": "defend", "actor": actor.id}
	return {"type": "invalid", "message": "未知技能"}

func _resolve_attack(actor, target, skill: Dictionary) -> Dictionary:
	var power := float(skill.get("power", 1.0))
	var raw_damage := int(max(1.0, actor.attack * power - target.defense * 0.55))
	return _apply_damage(actor, target, raw_damage, "attack")

func _resolve_element_damage(actor, target, skill: Dictionary) -> Dictionary:
	var mp_cost := int(skill.get("mp_cost", 0))
	if not actor.spend_mp(mp_cost):
		var line := "%s 法力不足。" % actor.display_name
		state.add_log(line)
		return {"type": "invalid", "message": line}
	var power := float(skill.get("power", 1.0))
	var modifier := ElementRules.get_modifier(str(skill.get("element", actor.element)), target.element)
	var raw_damage := int(max(1.0, (actor.magic * power - target.defense * 0.35) * modifier))
	return _apply_damage(actor, target, raw_damage, "damage")

func _resolve_heal(actor, target, skill: Dictionary) -> Dictionary:
	var mp_cost := int(skill.get("mp_cost", 0))
	if not actor.spend_mp(mp_cost):
		var line := "%s 法力不足。" % actor.display_name
		state.add_log(line)
		return {"type": "invalid", "message": line}
	var amount := int(actor.magic * float(skill.get("power", 1.0)) + actor.dao * 0.12)
	var actual := target.heal(amount)
	var line := "%s 为 %s 恢复 %d 气血。" % [actor.display_name, target.display_name, actual]
	state.add_log(line)
	return {"type": "heal", "actor": actor.id, "target": target.id, "amount": actual, "message": line}

func _resolve_control(actor, target, skill: Dictionary) -> Dictionary:
	var mp_cost := int(skill.get("mp_cost", 0))
	if not actor.spend_mp(mp_cost):
		var line := "%s 法力不足。" % actor.display_name
		state.add_log(line)
		return {"type": "invalid", "message": line}
	var chance := clamp(float(skill.get("base_chance", 0.5)) + (actor.dao - target.dao) * 0.003 - target.resist_control, 0.2, 0.85)
	var success := rng.randf() <= chance
	var line := ""
	if success:
		target.add_status("controlled", int(skill.get("duration", 1)))
		line = "%s 施放 %s，%s 被缠绕。" % [actor.display_name, skill.get("name", "障碍"), target.display_name]
	else:
		line = "%s 施放 %s，%s 抵抗成功。" % [actor.display_name, skill.get("name", "障碍"), target.display_name]
	state.add_log(line)
	return {"type": "control", "actor": actor.id, "target": target.id, "success": success, "message": line}

func _apply_damage(actor, target, amount: int, event_type: String) -> Dictionary:
	var damage := amount
	if target.is_defending:
		damage = int(ceil(damage * 0.55))
	var actual := target.apply_damage(damage)
	var line := "%s 攻击 %s，造成 %d 伤害。" % [actor.display_name, target.display_name, actual]
	state.add_log(line)
	return {"type": event_type, "actor": actor.id, "target": target.id, "amount": actual, "message": line}
```

- [ ] **Step 3: 运行测试**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Battle tests passed
```

---

### Task 6: 实现回合控制和敌人 AI

**Files:**
- Create: `scripts/battle/BattleController.gd`
- Modify: `tests/battle/BattleRuleTests.gd`

- [ ] **Step 1: 增加回合流程测试**

在 `tests/battle/BattleRuleTests.gd` 顶部加入：

```gdscript
const BattleController = preload("res://scripts/battle/BattleController.gd")
```

在 `run()` 中 `return failures` 前加入：

```gdscript
	var controller := BattleController.new()
	controller.setup("res://data/units.json", "res://data/skills.json")
	var result_events := controller.submit_player_round(
		BattleAction.make("hero", "enemy_1", "wood_spell", "element_damage"),
		BattleAction.make("pet", "enemy_1", "pet_claw", "pet_attack")
	)
	if result_events.is_empty():
		failures.append("提交一回合后应产生事件")
	_assert_equal(controller.state.round_number, 2, "执行一回合后回合数应增加", failures)
	for event in result_events:
		if event.get("type", "") == "defend" and str(event.get("actor", "")).begins_with("enemy"):
			failures.append("敌人不应生成防御行动")
```

- [ ] **Step 2: 实现回合控制器**

写入 `scripts/battle/BattleController.gd`：

```gdscript
class_name BattleController
extends RefCounted

const BattleState = preload("res://scripts/battle/BattleState.gd")
const SkillDatabase = preload("res://scripts/battle/SkillDatabase.gd")
const BattleResolver = preload("res://scripts/battle/BattleResolver.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")

var state := BattleState.new()
var skills := SkillDatabase.new()
var resolver
var auto_battle := false
var rng := RandomNumberGenerator.new()

func setup(units_path: String, skills_path: String) -> void:
	state = BattleState.new()
	state.load_units_from_path(units_path)
	skills = SkillDatabase.new()
	skills.load_from_path(skills_path)
	resolver = BattleResolver.new(state, skills)
	rng.seed = 24680

func submit_player_round(hero_action: BattleAction, pet_action: BattleAction) -> Array[Dictionary]:
	var actions: Array[BattleAction] = []
	actions.append(hero_action)
	if state.get_unit("pet") != null and state.get_unit("pet").is_alive():
		actions.append(pet_action)
	actions.append_array(_build_enemy_actions())
	actions.sort_custom(func(a: BattleAction, b: BattleAction) -> bool:
		return state.get_unit(a.actor_id).speed > state.get_unit(b.actor_id).speed
	)
	var events: Array[Dictionary] = []
	for action in actions:
		if state.battle_result != "":
			break
		var event := resolver.resolve(action)
		events.append(event)
		state.check_result()
	for unit in state.units:
		unit.is_defending = false
	if state.battle_result == "":
		state.round_number += 1
	return events

func build_auto_round() -> Array[Dictionary]:
	var target_id := _first_living_enemy_id()
	return submit_player_round(
		BattleAction.make("hero", target_id, "attack", "attack"),
		BattleAction.make("pet", target_id, "pet_claw", "pet_attack")
	)

func _build_enemy_actions() -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	var hero_target := "hero"
	if state.get_unit("hero") == null or not state.get_unit("hero").is_alive():
		hero_target = "pet"
	for enemy in state.get_living_enemies():
		var target_id := hero_target
		if state.get_unit("pet") != null and state.get_unit("pet").is_alive() and rng.randf() < 0.18:
			target_id = "pet"
		var skill_id := "attack"
		var action_type := "attack"
		if enemy.id == "enemy_boss":
			var roll := rng.randf()
			if roll < 0.2:
				skill_id = "boss_bind"
				action_type = "control"
			elif roll < 0.45:
				skill_id = "boss_fire"
				action_type = "element_damage"
		elif enemy.id == "enemy_3" and rng.randf() < 0.25:
			skill_id = "boss_fire"
			action_type = "element_damage"
		actions.append(BattleAction.make(enemy.id, target_id, skill_id, action_type))
	return actions

func _first_living_enemy_id() -> String:
	var enemies := state.get_living_enemies()
	if enemies.is_empty():
		return ""
	return enemies[0].id
```

- [ ] **Step 3: 运行测试**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Battle tests passed
```

---

### Task 7: 创建经典战斗 UI 子场景

**Files:**
- Create: `scenes/battle/UnitView.tscn`
- Create: `scenes/battle/UnitView.gd`
- Create: `scenes/battle/CommandPanel.tscn`
- Create: `scenes/battle/CommandPanel.gd`
- Create: `scenes/battle/BattleLog.tscn`
- Create: `scenes/battle/BattleLog.gd`

- [ ] **Step 1: 创建单位视图脚本**

写入 `scenes/battle/UnitView.gd`：

```gdscript
extends Control

@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HpBar
@onready var sprite_box: ColorRect = $SpriteBox

var unit_id := ""

func bind_unit(unit) -> void:
	unit_id = unit.id
	name_label.text = unit.display_name
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.hp
	modulate = Color.WHITE if unit.is_alive() else Color(0.35, 0.35, 0.35, 0.8)

func flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.55, 0.55), 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
```

- [ ] **Step 2: 创建单位视图场景**

写入 `scenes/battle/UnitView.tscn`：

```ini
[gd_scene load_steps=2 format=3 uid="uid://unit_view"]

[ext_resource type="Script" path="res://scenes/battle/UnitView.gd" id="1"]

[node name="UnitView" type="Control"]
custom_minimum_size = Vector2(86, 118)
script = ExtResource("1")

[node name="SpriteBox" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 14.0
offset_top = 0.0
offset_right = 72.0
offset_bottom = 78.0
color = Color(0.8, 0.35, 0.25, 1)

[node name="NameLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 0.0
offset_top = 82.0
offset_right = 86.0
offset_bottom = 104.0
horizontal_alignment = 1

[node name="HpBar" type="ProgressBar" parent="."]
layout_mode = 0
offset_left = 8.0
offset_top = 104.0
offset_right = 78.0
offset_bottom = 116.0
show_percentage = false
```

- [ ] **Step 3: 创建指令面板脚本**

写入 `scenes/battle/CommandPanel.gd`：

```gdscript
extends VBoxContainer

signal command_selected(command: String)

const COMMANDS := ["自动", "法术", "道具", "防御", "召唤", "召回", "保护", "捕捉", "逃跑"]

func _ready() -> void:
	for command in COMMANDS:
		var button := Button.new()
		button.text = command
		button.custom_minimum_size = Vector2(86, 42)
		button.pressed.connect(func() -> void: command_selected.emit(command))
		add_child(button)
```

- [ ] **Step 4: 创建指令面板场景**

写入 `scenes/battle/CommandPanel.tscn`：

```ini
[gd_scene load_steps=2 format=3 uid="uid://command_panel"]

[ext_resource type="Script" path="res://scenes/battle/CommandPanel.gd" id="1"]

[node name="CommandPanel" type="VBoxContainer"]
offset_left = 920.0
offset_top = 148.0
offset_right = 1016.0
offset_bottom = 556.0
theme_override_constants/separation = 6
script = ExtResource("1")
```

- [ ] **Step 5: 创建战报脚本**

写入 `scenes/battle/BattleLog.gd`：

```gdscript
extends PanelContainer

@onready var label: Label = $MarginContainer/Label

func set_lines(lines: Array[String]) -> void:
	label.text = "\n".join(lines)

func set_prompt(text: String) -> void:
	label.text = text + "\n" + label.text
```

- [ ] **Step 6: 创建战报场景**

写入 `scenes/battle/BattleLog.tscn`：

```ini
[gd_scene load_steps=2 format=3 uid="uid://battle_log"]

[ext_resource type="Script" path="res://scenes/battle/BattleLog.gd" id="1"]

[node name="BattleLog" type="PanelContainer"]
offset_left = 12.0
offset_top = 692.0
offset_right = 646.0
offset_bottom = 760.0
script = ExtResource("1")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 8
theme_override_constants/margin_top = 6
theme_override_constants/margin_right = 8
theme_override_constants/margin_bottom = 6

[node name="Label" type="Label" parent="MarginContainer"]
layout_mode = 2
text = "当前：请选择行动。"
```

- [ ] **Step 7: 运行项目检查场景资源**

Run:

```powershell
godot --headless --path . --quit
```

Expected:

```text
no parse errors
```

---

### Task 8: 组装主战斗场景 UI 和交互

**Files:**
- Modify: `scenes/battle/BattleScene.tscn`
- Modify: `scenes/battle/BattleScene.gd`

- [ ] **Step 1: 替换主场景为经典战斗布局**

写入 `scenes/battle/BattleScene.tscn`：

```ini
[gd_scene load_steps=5 format=3 uid="uid://battle_scene"]

[ext_resource type="Script" path="res://scenes/battle/BattleScene.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/battle/UnitView.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/battle/CommandPanel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/battle/BattleLog.tscn" id="4"]

[node name="BattleScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Battlefield" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.06, 0.28, 0.32, 1)

[node name="BackgroundTexture" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
stretch_mode = 6

[node name="RoundLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 420.0
offset_top = 14.0
offset_right = 604.0
offset_bottom = 54.0
theme_override_font_sizes/font_size = 28
horizontal_alignment = 1
text = "第 1 回合"

[node name="PetStatus" type="PanelContainer" parent="."]
layout_mode = 0
offset_left = 8.0
offset_top = 8.0
offset_right = 286.0
offset_bottom = 92.0

[node name="PetStatusLabel" type="Label" parent="PetStatus"]
layout_mode = 2
text = "灵狐  HP / MP"

[node name="HeroStatus" type="PanelContainer" parent="."]
layout_mode = 0
offset_left = 738.0
offset_top = 8.0
offset_right = 1016.0
offset_bottom = 92.0

[node name="HeroStatusLabel" type="Label" parent="HeroStatus"]
layout_mode = 2
text = "青玄  HP / MP"

[node name="EnemyUnits" type="Control" parent="."]
layout_mode = 0
offset_left = 58.0
offset_top = 142.0
offset_right = 520.0
offset_bottom = 318.0

[node name="AllyUnits" type="Control" parent="."]
layout_mode = 0
offset_left = 520.0
offset_top = 436.0
offset_right = 904.0
offset_bottom = 620.0

[node name="CommandPanel" parent="." instance=ExtResource("3")]

[node name="BattleLog" parent="." instance=ExtResource("4")]

[node name="QuickBar" type="HBoxContainer" parent="."]
layout_mode = 0
offset_left = 660.0
offset_top = 700.0
offset_right = 1014.0
offset_bottom = 758.0
theme_override_constants/separation = 6
```

- [ ] **Step 2: 实现主场景逻辑**

写入 `scenes/battle/BattleScene.gd`：

```gdscript
extends Control

const BattleController = preload("res://scripts/battle/BattleController.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")
const UnitViewScene = preload("res://scenes/battle/UnitView.tscn")

@onready var round_label: Label = $RoundLabel
@onready var enemy_units: Control = $EnemyUnits
@onready var ally_units: Control = $AllyUnits
@onready var command_panel = $CommandPanel
@onready var battle_log = $BattleLog
@onready var quick_bar: HBoxContainer = $QuickBar

var controller := BattleController.new()
var selected_skill_id := "attack"
var pending_hero_action = null

func _ready() -> void:
	controller.setup("res://data/units.json", "res://data/skills.json")
	command_panel.command_selected.connect(_on_command_selected)
	_build_quickbar()
	_load_background_if_available()
	_spawn_unit_views()
	_refresh_all()

func _load_background_if_available() -> void:
	var path := "res://assets/battle/backgrounds/lotus_pond_battle.png"
	if ResourceLoader.exists(path):
		$BackgroundTexture.texture = load(path)

func _build_quickbar() -> void:
	for text in ["金", "木", "水", "火", "土", "包", "宠", "队", "?"]:
		var button := Button.new()
		button.text = text
		button.custom_minimum_size = Vector2(36, 42)
		quick_bar.add_child(button)

func _spawn_unit_views() -> void:
	for child in enemy_units.get_children():
		child.queue_free()
	for child in ally_units.get_children():
		child.queue_free()
	var enemy_index := 0
	var ally_index := 0
	for unit in controller.state.units:
		var view = UnitViewScene.instantiate()
		view.name = unit.id
		view.bind_unit(unit)
		if unit.side == "enemy":
			enemy_units.add_child(view)
			view.position = Vector2(enemy_index * 92, enemy_index * 26)
			enemy_index += 1
		else:
			ally_units.add_child(view)
			view.position = Vector2(ally_index * 96, ally_index * -22)
			ally_index += 1
		view.gui_input.connect(func(event: InputEvent, id := unit.id) -> void:
			if event is InputEventMouseButton and event.pressed:
				_on_unit_clicked(id)
		)

func _on_command_selected(command: String) -> void:
	match command:
		"自动":
			var events := controller.build_auto_round()
			_after_round(events)
		"法术":
			selected_skill_id = "wood_spell"
			battle_log.set_prompt("当前：已选择青木诀，请点击敌方目标。再次点击法术会切换到青藤缠。")
		"防御":
			pending_hero_action = BattleAction.make("hero", "hero", "attack", "defend")
			battle_log.set_prompt("当前：角色防御，请点击敌方目标作为宠物攻击目标。")
		_:
			battle_log.set_prompt("当前：%s 暂未开放。" % command)

func _on_unit_clicked(unit_id: String) -> void:
	var target = controller.state.get_unit(unit_id)
	if target == null:
		return
	if pending_hero_action == null:
		if target.side != "enemy":
			battle_log.set_prompt("当前：伤害技能只能选择敌方目标。")
			return
		pending_hero_action = BattleAction.make("hero", unit_id, selected_skill_id, "element_damage")
		battle_log.set_prompt("当前：已选择角色行动，请再次点击敌方目标作为宠物目标。")
		return
	if target.side != "enemy":
		battle_log.set_prompt("当前：宠物攻击只能选择敌方目标。")
		return
	var pet_action := BattleAction.make("pet", unit_id, "pet_claw", "pet_attack")
	var events := controller.submit_player_round(pending_hero_action, pet_action)
	pending_hero_action = null
	selected_skill_id = "attack"
	_after_round(events)

func _after_round(_events: Array[Dictionary]) -> void:
	_refresh_all()
	if controller.state.battle_result == "victory":
		_show_result("战斗胜利", "灵气稳定，获得固定结算摘要。", "再战一场")
	elif controller.state.battle_result == "failure":
		_show_result("战斗失败", "道心不稳，请重新挑战。", "重新挑战")

func _refresh_all() -> void:
	round_label.text = "第 %d 回合" % controller.state.round_number
	$HeroStatus/HeroStatusLabel.text = _status_text("hero")
	$PetStatus/PetStatusLabel.text = _status_text("pet")
	for unit in controller.state.units:
		var view = enemy_units.get_node_or_null(unit.id)
		if view == null:
			view = ally_units.get_node_or_null(unit.id)
		if view != null:
			view.bind_unit(unit)
	battle_log.set_lines(controller.state.log_lines)

func _status_text(unit_id: String) -> String:
	var unit = controller.state.get_unit(unit_id)
	if unit == null:
		return ""
	return "%s  HP %d/%d  MP %d/%d" % [unit.display_name, unit.hp, unit.max_hp, unit.mp, unit.max_mp]

func _show_result(title: String, message: String, button_text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = button_text
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		controller.setup("res://data/units.json", "res://data/skills.json")
		pending_hero_action = null
		selected_skill_id = "attack"
		_spawn_unit_views()
		_refresh_all()
		dialog.queue_free()
	)
	dialog.popup_centered()
```

- [ ] **Step 3: 修正法术选择为可切换**

在 `_on_command_selected()` 的 `"法术"` 分支替换为：

```gdscript
		"法术":
			if selected_skill_id == "wood_spell":
				selected_skill_id = "wood_bind"
				battle_log.set_prompt("当前：已选择青藤缠，请点击敌方目标。")
			elif selected_skill_id == "wood_bind":
				selected_skill_id = "spring_heal"
				battle_log.set_prompt("当前：已选择回春术，请点击我方目标。")
			else:
				selected_skill_id = "wood_spell"
				battle_log.set_prompt("当前：已选择青木诀，请点击敌方目标。")
```

- [ ] **Step 4: 修正目标选择支持治疗**

在 `_on_unit_clicked()` 中创建 `pending_hero_action` 的逻辑替换为：

```gdscript
	if pending_hero_action == null:
		if selected_skill_id == "spring_heal":
			if target.side == "enemy":
				battle_log.set_prompt("当前：治疗只能选择我方目标。")
				return
			pending_hero_action = BattleAction.make("hero", unit_id, "spring_heal", "heal")
			battle_log.set_prompt("当前：已选择角色治疗，请点击敌方目标作为宠物目标。")
			return
		if target.side != "enemy":
			battle_log.set_prompt("当前：伤害和障碍技能只能选择敌方目标。")
			return
		var action_type := "control" if selected_skill_id == "wood_bind" else "element_damage"
		pending_hero_action = BattleAction.make("hero", unit_id, selected_skill_id, action_type)
		battle_log.set_prompt("当前：已选择角色行动，请再次点击敌方目标作为宠物目标。")
		return
```

- [ ] **Step 5: 运行项目**

Run:

```powershell
godot --path .
```

Expected:

```text
打开 BattleScene，显示经典战斗 UI。
```

手动检查：

- 顶部左右状态框存在。
- 右侧竖向指令存在。
- 底部战报和快捷栏存在。
- 页面没有 `战斗目标` 竖条。

---

### Task 9: 完成验证和收尾

**Files:**
- Modify only files required by failed checks.

- [ ] **Step 1: 运行规则测试**

Run:

```powershell
godot --headless --path . --script tests/run_battle_tests.gd
```

Expected:

```text
Battle tests passed
```

- [ ] **Step 2: 运行 Godot 项目**

Run:

```powershell
godot --path .
```

Expected:

```text
主场景打开且无脚本错误。
```

- [ ] **Step 3: 手动验证战斗闭环**

检查清单：

```text
1. 点击法术后能选择青木诀、青藤缠、回春术。
2. 伤害和障碍技能不能点我方目标。
3. 治疗技能不能点敌方目标。
4. 角色和宠物能在同一回合行动。
5. 敌人行动事件里没有防御。
6. 五行法术伤害高于普通中性修正。
7. 青藤缠成功时目标跳过下一次行动。
8. 底部战报出现中文行动记录。
9. 敌方全灭显示战斗胜利。
10. 角色倒下显示战斗失败。
11. 再战一场或重新挑战能重置战斗。
12. UI 不包含战斗目标竖条。
13. 背景、角色、宠物、敌人和技能 FX 使用 `assets/` 下的原创资产。
14. 运行时没有引用现有游戏截图、UI 素材、角色素材或商标元素。
```

- [ ] **Step 4: 如果项目已初始化 Git，则提交**

Run:

```powershell
git status --short
```

Expected if repository exists:

```text
显示本次新增和修改文件。
```

Commit:

```powershell
git add project.godot data scripts scenes tests docs
git commit -m "feat: add lingdaoji battle prototype"
```

如果 `git status` 返回 `fatal: not a git repository`，不要初始化 Git，除非用户明确要求。

---

## 自检结果

Spec 覆盖：

- 美术方向、资产清单、提示词和生产路径：Task 0。
- Godot 4.6.x 项目骨架：Task 1。
- 五行克制：Task 2。
- 单位和技能数据：Task 3。
- 技能加载和战斗状态：Task 4。
- 伤害、治疗、控制、防御：Task 5。
- 回合流程、宠物参战、敌人不防御：Task 6。
- 经典布局、无 `战斗目标` 竖条：Task 7 和 Task 8。
- 胜负结算和重置：Task 8。
- 测试与手动验证：Task 9。

计划未包含地图、账号、背包、商城、任务、帮派、宠物养成、经验、金钱或掉落系统，符合第一版范围。
