extends RefCounted

const ElementRules = preload("res://scripts/battle/ElementRules.gd")
const BattleUnit = preload("res://scripts/battle/BattleUnit.gd")
const SkillDatabase = preload("res://scripts/battle/SkillDatabase.gd")
const BattleState = preload("res://scripts/battle/BattleState.gd")
const BattleResolver = preload("res://scripts/battle/BattleResolver.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")
const BattleController = preload("res://scripts/battle/BattleController.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_assert_equal(ElementRules.get_modifier("metal", "wood"), 1.2, "金克木应为 1.2", failures)
	_assert_equal(ElementRules.get_modifier("wood", "metal"), 0.9, "木被金克应为 0.9", failures)
	_assert_equal(ElementRules.get_modifier("water", "earth"), 0.9, "水被土克应为 0.9", failures)
	_assert_equal(ElementRules.get_modifier("fire", "water"), 0.9, "火被水克应为 0.9", failures)
	_assert_equal(ElementRules.get_modifier("earth", "fire"), 1.0, "土与火无直接克制应为 1.0", failures)

	var unit: BattleUnit = BattleUnit.from_dict({
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

	var animated_unit: BattleUnit = BattleUnit.from_dict({
		"id": "animated_hero",
		"name": "动画角色",
		"side": "player",
		"element": "wood",
		"hp": 100,
		"mp": 50,
		"attack": 20,
		"defense": 5,
		"magic": 30,
		"speed": 10,
		"dao": 100,
		"resist_control": 0.1,
		"sprite": "res://assets/battle/units/hero_qingxuan.png",
		"sprite_sheet": "res://assets/battle/units/hero_qingxuan/idle_8dir.png",
		"sprite_sheet_columns": 4,
		"sprite_sheet_rows": 2,
		"combat_frame": 5,
		"animations": {
			"attack": {
				"sheet": "res://assets/battle/units/hero_qingxuan/attack_combat.png",
				"columns": 2,
				"rows": 2,
				"frames": 4,
				"fps": 10
			}
		}
	})
	_assert_equal(animated_unit.sprite_sheet_path, "res://assets/battle/units/hero_qingxuan/idle_8dir.png", "单位应能加载动画表路径", failures)
	_assert_equal(animated_unit.sprite_sheet_columns, 4, "单位应能加载动画表列数", failures)
	_assert_equal(animated_unit.sprite_sheet_rows, 2, "单位应能加载动画表行数", failures)
	_assert_equal(animated_unit.combat_frame, 5, "单位应能加载战斗朝向帧", failures)
	_assert_equal(animated_unit.animations.has("attack"), true, "单位应能加载动作表配置", failures)
	_assert_equal(animated_unit.animations.get("attack", {}).get("frames", 0), 4, "动作表应能加载帧数", failures)

	var skills: SkillDatabase = SkillDatabase.new()
	var load_result: bool = skills.load_from_path("res://data/skills.json")
	_assert_equal(load_result, true, "技能配置应能加载", failures)
	_assert_equal(skills.get_skill("wood_bind").get("name", ""), "青藤缠", "应能按 id 查询技能", failures)

	var state: BattleState = BattleState.new()
	state.load_units_from_path("res://data/units.json")
	_assert_equal(state.get_unit("hero").display_name, "青玄", "应能加载角色", failures)
	_assert_equal(state.get_living_enemies().size(), 4, "应加载四个敌人", failures)

	var resolver_state: BattleState = BattleState.new()
	resolver_state.load_units_from_path("res://data/units.json")
	var resolver_skills: SkillDatabase = SkillDatabase.new()
	resolver_skills.load_from_path("res://data/skills.json")
	var resolver: BattleResolver = BattleResolver.new(resolver_state, resolver_skills)
	var enemy: BattleUnit = resolver_state.get_unit("enemy_1")
	var old_hp: int = enemy.hp
	var damage_event: Dictionary = resolver.resolve(BattleAction.make("hero", "enemy_1", "wood_spell", "element_damage"))
	_assert_equal(damage_event.get("type", ""), "damage", "五行法术应造成伤害", failures)
	_assert_equal(damage_event.get("animation", ""), "cast", "五行法术应触发施法动作", failures)
	if enemy.hp >= old_hp:
		failures.append("五行法术后敌人气血应下降")

	var hero: BattleUnit = resolver_state.get_unit("hero")
	hero.apply_damage(200)
	var damaged_hp: int = hero.hp
	var heal_event: Dictionary = resolver.resolve(BattleAction.make("hero", "hero", "spring_heal", "heal"))
	_assert_equal(heal_event.get("type", ""), "heal", "治疗应返回 heal 事件", failures)
	_assert_equal(heal_event.get("animation", ""), "cast", "治疗应触发施法动作", failures)
	if hero.hp <= damaged_hp:
		failures.append("治疗后角色气血应上升")

	var control_target: BattleUnit = resolver_state.get_unit("enemy_2")
	var control_event: Dictionary = resolver.resolve(BattleAction.make("hero", "enemy_2", "wood_bind", "control"))
	_assert_equal(control_event.has("success"), true, "控制事件应包含 success 字段", failures)
	if control_event.get("success", false) and not control_target.has_status("controlled"):
		failures.append("控制成功后目标应有 controlled 状态")

	var controller: BattleController = BattleController.new()
	controller.setup("res://data/units.json", "res://data/skills.json")
	var result_events: Array[Dictionary] = controller.submit_player_round(
		BattleAction.make("hero", "enemy_1", "wood_spell", "element_damage"),
		BattleAction.make("pet", "enemy_1", "pet_claw", "pet_attack")
	)
	if result_events.is_empty():
		failures.append("提交一回合后应产生事件")
	for event: Dictionary in result_events:
		if event.get("type", "") in ["attack", "damage", "heal", "control", "defend"] and str(event.get("animation", "")) == "":
			failures.append("战斗事件应包含前端动作名")
	_assert_equal(controller.state.round_number, 2, "执行一回合后回合数应增加", failures)
	for event: Dictionary in result_events:
		if event.get("type", "") == "defend" and str(event.get("actor", "")).begins_with("enemy"):
			failures.append("敌人不应生成防御行动")
	return failures

func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s: expected=%s actual=%s" % [message, str(expected), str(actual)])
