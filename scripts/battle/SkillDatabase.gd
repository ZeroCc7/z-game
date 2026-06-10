class_name SkillDatabase
extends RefCounted

var skills_by_id: Dictionary = {}

func load_from_path(path: String) -> bool:
	var text: String = FileAccess.get_file_as_string(path)
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
