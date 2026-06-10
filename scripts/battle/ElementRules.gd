class_name ElementRules
extends RefCounted

const COUNTERS: Dictionary = {
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
