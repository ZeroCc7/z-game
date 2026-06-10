extends PanelContainer

@onready var label: Label = $MarginContainer/Label

func set_lines(lines: Array[String]) -> void:
	if lines.is_empty():
		label.text = "当前：请选择行动。"
	else:
		label.text = "\n".join(lines)

func set_prompt(text: String) -> void:
	label.text = text + "\n" + label.text
