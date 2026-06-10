class_name BattleResolver
extends RefCounted

const ElementRules = preload("res://scripts/battle/ElementRules.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")

var state: BattleState
var skills: SkillDatabase
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(state_value: BattleState = null, skills_value: SkillDatabase = null) -> void:
	state = state_value
	skills = skills_value
	rng.seed = 12345

func resolve(action: BattleAction) -> Dictionary:
	var actor: BattleUnit = state.get_unit(action.actor_id)
	var target: BattleUnit = state.get_unit(action.target_id)
	var skill: Dictionary = skills.get_skill(action.skill_id)
	if actor == null or target == null or not actor.is_alive():
		return {"type": "invalid", "message": "行动无效"}
	if actor.consume_control_if_present():
		var skip_line: String = "%s 被障碍控制，跳过行动。" % actor.display_name
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
			return {"type": "defend", "actor": actor.id, "animation": "defend"}
	return {"type": "invalid", "message": "未知技能"}

func _resolve_attack(actor: BattleUnit, target: BattleUnit, skill: Dictionary) -> Dictionary:
	var power: float = float(skill.get("power", 1.0))
	var raw_damage: int = int(maxf(1.0, actor.attack * power - target.defense * 0.55))
	return _apply_damage(actor, target, raw_damage, "attack", "", "attack")

func _resolve_element_damage(actor: BattleUnit, target: BattleUnit, skill: Dictionary) -> Dictionary:
	var mp_cost: int = int(skill.get("mp_cost", 0))
	if not actor.spend_mp(mp_cost):
		var line: String = "%s 法力不足。" % actor.display_name
		state.add_log(line)
		return {"type": "invalid", "message": line}
	var power: float = float(skill.get("power", 1.0))
	var modifier: float = ElementRules.get_modifier(str(skill.get("element", actor.element)), target.element)
	var raw_damage: int = int(maxf(1.0, (actor.magic * power - target.defense * 0.35) * modifier))
	return _apply_damage(actor, target, raw_damage, "damage", skill.get("fx", ""), "cast")

func _resolve_heal(actor: BattleUnit, target: BattleUnit, skill: Dictionary) -> Dictionary:
	var mp_cost: int = int(skill.get("mp_cost", 0))
	if not actor.spend_mp(mp_cost):
		var line: String = "%s 法力不足。" % actor.display_name
		state.add_log(line)
		return {"type": "invalid", "message": line}
	var amount: int = int(actor.magic * float(skill.get("power", 1.0)) + actor.dao * 0.12)
	var actual: int = target.heal(amount)
	var line: String = "%s 为 %s 恢复 %d 气血。" % [actor.display_name, target.display_name, actual]
	state.add_log(line)
	return {"type": "heal", "actor": actor.id, "target": target.id, "amount": actual, "message": line, "fx": skill.get("fx", ""), "animation": "cast"}

func _resolve_control(actor: BattleUnit, target: BattleUnit, skill: Dictionary) -> Dictionary:
	var mp_cost: int = int(skill.get("mp_cost", 0))
	if not actor.spend_mp(mp_cost):
		var line: String = "%s 法力不足。" % actor.display_name
		state.add_log(line)
		return {"type": "invalid", "message": line}
	var chance: float = clampf(float(skill.get("base_chance", 0.5)) + (actor.dao - target.dao) * 0.003 - target.resist_control, 0.2, 0.85)
	var success: bool = rng.randf() <= chance
	var line: String = ""
	if success:
		target.add_status("controlled", int(skill.get("duration", 1)))
		line = "%s 施放 %s，%s 被缠绕。" % [actor.display_name, skill.get("name", "障碍"), target.display_name]
	else:
		line = "%s 施放 %s，%s 抵抗成功。" % [actor.display_name, skill.get("name", "障碍"), target.display_name]
	state.add_log(line)
	return {"type": "control", "actor": actor.id, "target": target.id, "success": success, "message": line, "fx": skill.get("fx", ""), "animation": "cast"}

func _apply_damage(actor: BattleUnit, target: BattleUnit, amount: int, event_type: String, fx_path: String = "", animation: String = "attack") -> Dictionary:
	var damage: int = amount
	if target.is_defending:
		damage = int(ceil(damage * 0.55))
	var actual: int = target.apply_damage(damage)
	var line: String = "%s 攻击 %s，造成 %d 伤害。" % [actor.display_name, target.display_name, actual]
	state.add_log(line)
	return {"type": event_type, "actor": actor.id, "target": target.id, "amount": actual, "message": line, "fx": fx_path, "animation": animation}
