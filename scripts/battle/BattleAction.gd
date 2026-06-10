class_name BattleAction
extends RefCounted

var actor_id: String
var target_id: String
var skill_id: String
var action_type: String

static func make(actor_id_value: String, target_id_value: String, skill_id_value: String, type_value: String) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.actor_id = actor_id_value
	action.target_id = target_id_value
	action.skill_id = skill_id_value
	action.action_type = type_value
	return action
