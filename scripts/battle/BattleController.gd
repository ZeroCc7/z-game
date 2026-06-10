class_name BattleController
extends RefCounted

const BattleState = preload("res://scripts/battle/BattleState.gd")
const SkillDatabase = preload("res://scripts/battle/SkillDatabase.gd")
const BattleResolver = preload("res://scripts/battle/BattleResolver.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")

var state: BattleState = BattleState.new()
var skills: SkillDatabase = SkillDatabase.new()
var resolver: BattleResolver
var auto_battle: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

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
		var event: Dictionary = resolver.resolve(action)
		events.append(event)
		state.check_result()
	for unit in state.units:
		unit.is_defending = false
	if state.battle_result == "":
		state.round_number += 1
	return events

func build_auto_round() -> Array[Dictionary]:
	var target_id: String = _first_living_enemy_id()
	return submit_player_round(
		BattleAction.make("hero", target_id, "attack", "attack"),
		BattleAction.make("pet", target_id, "pet_claw", "pet_attack")
	)

func _build_enemy_actions() -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	var hero_target: String = "hero"
	if state.get_unit("hero") == null or not state.get_unit("hero").is_alive():
		hero_target = "pet"
	for enemy: BattleUnit in state.get_living_enemies():
		var target_id: String = hero_target
		if state.get_unit("pet") != null and state.get_unit("pet").is_alive() and rng.randf() < 0.18:
			target_id = "pet"
		var skill_id: String = "attack"
		var action_type: String = "attack"
		if enemy.id == "enemy_boss":
			var roll: float = rng.randf()
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
	var enemies: Array[BattleUnit] = state.get_living_enemies()
	if enemies.is_empty():
		return ""
	return enemies[0].id
