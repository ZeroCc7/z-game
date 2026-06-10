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
