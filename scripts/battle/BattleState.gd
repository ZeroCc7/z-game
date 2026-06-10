class_name BattleState
extends RefCounted

const BattleUnit = preload("res://scripts/battle/BattleUnit.gd")

var round_number: int = 1
var units: Array[BattleUnit] = []
var battle_result: String = ""
var log_lines: Array[String] = []

func load_units_from_path(path: String) -> bool:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return false
	units.clear()
	for item: Variant in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			units.append(BattleUnit.from_dict(item))
	return true

func get_unit(unit_id: String) -> BattleUnit:
	for unit: BattleUnit in units:
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
	var hero: BattleUnit = get_unit("hero")
	if battle_result == "" and (hero == null or not hero.is_alive()):
		battle_result = "failure"
	return battle_result
