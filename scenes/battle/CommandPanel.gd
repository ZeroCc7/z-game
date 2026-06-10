extends HBoxContainer

signal command_selected(command: String)

const COMMANDS: Array[String] = ["法术", "防御", "自动", "道具", "召唤", "保护"]

func _ready() -> void:
	for command in COMMANDS:
		var button: Button = Button.new()
		button.text = command
		button.custom_minimum_size = Vector2(88, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: command_selected.emit(command))
		add_child(button)
