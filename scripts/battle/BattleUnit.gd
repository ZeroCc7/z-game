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
var sprite_path: String
var sprite_sheet_path: String = ""
var sprite_sheet_columns: int = 1
var sprite_sheet_rows: int = 1
var combat_frame: int = 0
var animations: Dictionary = {}
var status_effects: Array[Dictionary] = []
var is_defending: bool = false

static func from_dict(data: Dictionary) -> BattleUnit:
	var unit: BattleUnit = BattleUnit.new()
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
	unit.sprite_path = data.get("sprite", "")
	unit.sprite_sheet_path = data.get("sprite_sheet", "")
	unit.sprite_sheet_columns = int(data.get("sprite_sheet_columns", 1))
	unit.sprite_sheet_rows = int(data.get("sprite_sheet_rows", 1))
	unit.combat_frame = int(data.get("combat_frame", 0))
	unit.animations = data.get("animations", {})
	return unit

func is_alive() -> bool:
	return hp > 0

func apply_damage(amount: int) -> int:
	var actual: int = maxi(amount, 0)
	hp = max(hp - actual, 0)
	return actual

func heal(amount: int) -> int:
	var before: int = hp
	hp = mini(hp + maxi(amount, 0), max_hp)
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
	for index: int in range(status_effects.size()):
		if status_effects[index].get("id", "") == "controlled":
			status_effects.remove_at(index)
			return true
	return false
