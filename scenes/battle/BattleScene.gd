extends Control

const BattleController = preload("res://scripts/battle/BattleController.gd")
const BattleAction = preload("res://scripts/battle/BattleAction.gd")
const UnitViewScene = preload("res://scenes/battle/UnitView.tscn")

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var round_label: Label = $RoundLabel
@onready var enemy_units: Control = $EnemyUnits
@onready var ally_units: Control = $AllyUnits
@onready var command_panel: HBoxContainer = $CommandPanel
@onready var battle_log: PanelContainer = $BattleLog
@onready var quick_bar: HBoxContainer = $QuickBar
@onready var hero_status: PanelContainer = $HeroStatus
@onready var hero_status_label: Label = $HeroStatus/MarginContainer/HeroStatusLabel
@onready var pet_status: PanelContainer = $PetStatus
@onready var pet_status_label: Label = $PetStatus/MarginContainer/PetStatusLabel
@onready var bottom_shade: ColorRect = $BottomShade
@onready var fx_layer: Control = $FxLayer

var controller: BattleController = BattleController.new()
var selected_skill_id: String = "attack"
var pending_hero_action: BattleAction = null
var is_playing_events: bool = false
var skill_buttons: Array[Button] = []
const SKILL_ICON_PATHS: Array[String] = [
	"res://assets/ui/battle/skill_wood.png",
	"res://assets/ui/battle/skill_defend.png",
	"res://assets/ui/battle/skill_auto.png",
	"res://assets/ui/battle/skill_item.png",
	"res://assets/ui/battle/skill_summon.png",
	"res://assets/ui/battle/skill_summon.png",
]

func _ready() -> void:
	controller.setup("res://data/units.json", "res://data/skills.json")
	command_panel.command_selected.connect(_on_command_selected)
	_load_background_if_available()
	_build_cinematic_ui()
	_spawn_unit_views()
	_refresh_all()

func _load_background_if_available() -> void:
	var path: String = "res://assets/battle/backgrounds/sect_ruins_battle.png"
	if ResourceLoader.exists(path):
		background_texture.texture = load(path)

func _build_cinematic_ui() -> void:
	_apply_hud_layout()
	_style_panel(pet_status, Color(0.02, 0.015, 0.01, 0.78))
	_style_panel(hero_status, Color(0.02, 0.015, 0.01, 0.78))
	_style_panel(battle_log, Color(0.02, 0.015, 0.01, 0.62))
	_build_top_controls()
	_build_left_tactics()
	_build_right_info()
	_build_skill_dock()
	_build_end_turn_button()
	_build_hero_portrait()
	hero_status.z_index = 10
	pet_status.z_index = 10
	command_panel.z_index = 10
	battle_log.z_index = 10
	bottom_shade.z_index = 2
	fx_layer.z_index = 20

func _apply_hud_layout() -> void:
	round_label.position = Vector2(420, 38)
	round_label.size = Vector2(184, 28)
	round_label.add_theme_font_size_override("font_size", 18)
	enemy_units.position = Vector2(82, 150)
	enemy_units.size = Vector2(646, 288)
	ally_units.position = Vector2(500, 352)
	ally_units.size = Vector2(382, 220)
	hero_status.position = Vector2(118, 650)
	hero_status.size = Vector2(262, 40)
	pet_status.position = Vector2(118, 700)
	pet_status.size = Vector2(262, 40)
	battle_log.position = Vector2(386, 610)
	battle_log.size = Vector2(444, 52)
	bottom_shade.position = Vector2(0, 636)
	bottom_shade.size = Vector2(1024, 132)

func _build_top_controls() -> void:
	var labels: Array[String] = ["撤退", "x2", "自动", "跳过"]
	var commands: Array[String] = ["逃跑", "自动", "自动", "防御"]
	for index: int in range(labels.size()):
		var command: String = commands[index]
		var button: Button = _make_round_button(labels[index], 48)
		button.position = Vector2(30 + index * 64, 20)
		button.z_index = 8
		button.pressed.connect(func() -> void:
			_on_command_selected(command)
		)
		add_child(button)
	var title: Label = Label.new()
	title.text = "断金门之战"
	title.position = Vector2(422, 16)
	title.size = Vector2(180, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.z_index = 7
	add_child(title)
	for index: int in range(12):
		var dot: ColorRect = ColorRect.new()
		dot.position = Vector2(392 + index * 20, 64)
		dot.size = Vector2(9, 9)
		dot.color = Color(0.95, 0.63, 0.22, 0.95) if index in [0, 5, 11] else Color(0.08, 0.08, 0.08, 0.88)
		dot.z_index = 7
		add_child(dot)
	round_label.z_index = 7

func _build_left_tactics() -> void:
	var labels: Array[String] = ["指挥", "状态", "布阵"]
	for index: int in range(labels.size()):
		var button: Button = _make_round_button(labels[index], 48)
		button.position = Vector2(30, 404 + index * 62)
		button.z_index = 9
		add_child(button)

func _build_right_info() -> void:
	for index: int in range(2):
		var button: Button = _make_round_button(["天象", "战场"][index], 50)
		button.position = Vector2(946, 104 + index * 74)
		button.z_index = 9
		add_child(button)
	var plaque: Label = Label.new()
	plaque.text = "断金门\n剑意涌动\n伤害+15%"
	plaque.position = Vector2(916, 242)
	plaque.size = Vector2(96, 110)
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plaque.add_theme_font_size_override("font_size", 16)
	plaque.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48))
	plaque.add_theme_color_override("font_shadow_color", Color.BLACK)
	plaque.add_theme_stylebox_override("normal", _round_style(Color(0.025, 0.018, 0.012, 0.82), Color(0.75, 0.52, 0.26), 8, 2))
	plaque.z_index = 9
	add_child(plaque)

func _build_skill_dock() -> void:
	command_panel.position = Vector2(418, 682)
	command_panel.size = Vector2(424, 64)
	command_panel.add_theme_constant_override("separation", 10)
	quick_bar.visible = false
	var index: int = 0
	for child in command_panel.get_children():
		if child is Button:
			var button: Button = child
			var label_text: String = button.text
			button.text = ""
			button.custom_minimum_size = Vector2(58, 58)
			button.size = Vector2(58, 58)
			_style_round_button(button, 58)
			if index < SKILL_ICON_PATHS.size():
				_add_child_texture(button, SKILL_ICON_PATHS[index], Vector2(10, 8), Vector2(38, 34), 0)
			var label: Label = Label.new()
			label.text = label_text
			label.position = Vector2(2, 39)
			label.size = Vector2(54, 16)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
			label.add_theme_color_override("font_shadow_color", Color.BLACK)
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 1)
			button.add_child(label)
			skill_buttons.append(button)
			index += 1

func _build_end_turn_button() -> void:
	var button: Button = _make_round_button("结束\n回合", 104)
	button.position = Vector2(900, 626)
	button.z_index = 10
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(func() -> void:
		_on_command_selected("自动")
	)
	add_child(button)

func _build_hero_portrait() -> void:
	var portrait: TextureRect = TextureRect.new()
	if ResourceLoader.exists("res://assets/ui/battle/hero_portrait.png"):
		portrait.texture = load("res://assets/ui/battle/hero_portrait.png")
	portrait.position = Vector2(0, 568)
	portrait.size = Vector2(280, 200)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(portrait)
	portrait.z_index = 3

func _make_round_button(text: String, size_px: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(size_px, size_px)
	button.size = Vector2(size_px, size_px)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	_style_round_button(button, size_px)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	return button

func _style_round_button(button: Button, size_px: int) -> void:
	button.add_theme_stylebox_override("normal", _round_style(Color(0.018, 0.014, 0.01, 0.90), Color(0.86, 0.62, 0.28), size_px / 2, 2))
	button.add_theme_stylebox_override("hover", _round_style(Color(0.08, 0.05, 0.025, 0.95), Color(1.0, 0.78, 0.36), size_px / 2, 2))
	button.add_theme_stylebox_override("pressed", _round_style(Color(0.01, 0.018, 0.022, 0.98), Color(0.35, 0.84, 1.0), size_px / 2, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _add_child_texture(parent: Control, path: String, position_value: Vector2, size_value: Vector2, z: int) -> TextureRect:
	parent.clip_contents = true
	var texture_rect: TextureRect = TextureRect.new()
	if ResourceLoader.exists(path):
		texture_rect.texture = load(path)
	texture_rect.position = position_value
	texture_rect.size = size_value
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.z_index = z
	parent.add_child(texture_rect)
	return texture_rect

func _round_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _style_panel(panel: Control, fill: Color) -> void:
	if panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", _round_style(fill, Color(0.78, 0.55, 0.28), 6, 2))

func _spawn_unit_views() -> void:
	for child in enemy_units.get_children():
		child.queue_free()
	for child in ally_units.get_children():
		child.queue_free()
	var enemy_positions: Array[Vector2] = [
		Vector2(80, 122),
		Vector2(202, 92),
		Vector2(324, 62),
		Vector2(454, 30),
	]
	var ally_positions: Array[Vector2] = [
		Vector2(116, 46),
		Vector2(248, 18),
	]
	var enemy_index: int = 0
	var ally_index: int = 0
	for unit: BattleUnit in controller.state.units:
		var view: Control = UnitViewScene.instantiate()
		view.name = unit.id
		view.gui_input.connect(_on_unit_view_gui_input.bind(unit.id))
		if unit.side == "enemy":
			enemy_units.add_child(view)
			view.position = enemy_positions[min(enemy_index, enemy_positions.size() - 1)]
			view.z_index = int(view.position.y)
			enemy_index += 1
		else:
			ally_units.add_child(view)
			view.position = ally_positions[min(ally_index, ally_positions.size() - 1)]
			view.z_index = int(view.position.y)
			ally_index += 1
		view.bind_unit(unit)

func _on_command_selected(command: String) -> void:
	if is_playing_events:
		return
	match command:
		"自动":
			var events: Array[Dictionary] = controller.build_auto_round()
			_after_round(events)
		"法术":
			_cycle_spell()
		"防御":
			pending_hero_action = BattleAction.make("hero", "hero", "defend", "defend")
			battle_log.set_prompt("当前：角色防御，请点击敌方目标作为宠物攻击目标。")
		_:
			battle_log.set_prompt("当前：%s 暂未开放。" % command)

func _cycle_spell() -> void:
	if selected_skill_id == "wood_spell":
		selected_skill_id = "wood_bind"
		battle_log.set_prompt("当前：已选择青藤缠，请点击敌方目标。")
	elif selected_skill_id == "wood_bind":
		selected_skill_id = "spring_heal"
		battle_log.set_prompt("当前：已选择回春术，请点击我方目标。")
	else:
		selected_skill_id = "wood_spell"
		battle_log.set_prompt("当前：已选择青木诀，请点击敌方目标。")

func _on_unit_view_gui_input(event: InputEvent, unit_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_unit_clicked(unit_id)

func _on_unit_clicked(unit_id: String) -> void:
	if is_playing_events:
		return
	var target: BattleUnit = controller.state.get_unit(unit_id)
	if target == null or not target.is_alive():
		return
	if pending_hero_action == null:
		if selected_skill_id == "spring_heal":
			if target.side == "enemy":
				battle_log.set_prompt("当前：治疗只能选择我方目标。")
				return
			pending_hero_action = BattleAction.make("hero", unit_id, "spring_heal", "heal")
			battle_log.set_prompt("当前：已选择角色治疗，请点击敌方目标作为宠物目标。")
			return
		if target.side != "enemy":
			battle_log.set_prompt("当前：伤害和障碍技能只能选择敌方目标。")
			return
		var action_type: String = "attack"
		if selected_skill_id == "wood_bind":
			action_type = "control"
		elif selected_skill_id == "wood_spell":
			action_type = "element_damage"
		pending_hero_action = BattleAction.make("hero", unit_id, selected_skill_id, action_type)
		battle_log.set_prompt("当前：已选择角色行动，请再次点击敌方目标作为宠物目标。")
		return
	if target.side != "enemy":
		battle_log.set_prompt("当前：宠物攻击只能选择敌方目标。")
		return
	var pet_action: BattleAction = BattleAction.make("pet", unit_id, "pet_claw", "pet_attack")
	var events: Array[Dictionary] = controller.submit_player_round(pending_hero_action, pet_action)
	pending_hero_action = null
	selected_skill_id = "attack"
	_after_round(events)

func _after_round(events: Array[Dictionary]) -> void:
	_refresh_all()
	is_playing_events = true
	for event: Dictionary in events:
		_play_event_feedback(event)
		await get_tree().create_timer(0.52).timeout
	is_playing_events = false
	if controller.state.battle_result == "victory":
		_show_result("战斗胜利", "灵气稳定，获得固定结算摘要。", "再战一场")
	elif controller.state.battle_result == "failure":
		_show_result("战斗失败", "道心不稳，请重新挑战。", "重新挑战")

func _refresh_all() -> void:
	round_label.text = "第 %d 回合" % controller.state.round_number
	hero_status_label.text = _status_text("hero")
	pet_status_label.text = _status_text("pet")
	for unit in controller.state.units:
		var view: Control = _find_unit_view(unit.id)
		if view != null:
			view.bind_unit(unit)
	battle_log.set_lines(controller.state.log_lines)

func _status_text(unit_id: String) -> String:
	var unit: BattleUnit = controller.state.get_unit(unit_id)
	if unit == null:
		return ""
	return "%s  气血 %d/%d  法力 %d/%d" % [unit.display_name, unit.hp, unit.max_hp, unit.mp, unit.max_mp]

func _play_event_feedback(event: Dictionary) -> void:
	var target_id: String = str(event.get("target", ""))
	var actor_id: String = str(event.get("actor", ""))
	var view: Control = _find_unit_view(target_id)
	var actor_view: Control = _find_unit_view(actor_id)
	if actor_view != null:
		actor_view.play_action(str(event.get("animation", event.get("type", ""))), view.global_position if view != null else Vector2.ZERO)
	if view == null:
		return
	if event.get("type", "") in ["damage", "attack"]:
		view.play_action("hurt", actor_view.global_position if actor_view != null else Vector2.ZERO)
		view.flash_damage()
		_show_float_text(view, "-%d" % int(event.get("amount", 0)), Color(1.0, 0.88, 0.12))
	elif event.get("type", "") == "heal":
		_show_float_text(view, "+%d" % int(event.get("amount", 0)), Color(0.25, 1.0, 0.35))
	elif event.get("type", "") == "control" and event.get("success", false):
		_show_float_text(view, "缠绕", Color(0.35, 1.0, 0.45))
	var fx_path: String = str(event.get("fx", ""))
	if fx_path != "" and ResourceLoader.exists(fx_path):
		_show_fx(view, fx_path)

func _show_float_text(view: Control, text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	fx_layer.add_child(label)
	label.global_position = view.global_position + Vector2(26, -18)
	var tween: Tween = create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -34), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)

func _show_fx(view: Control, fx_path: String) -> void:
	var texture: TextureRect = TextureRect.new()
	texture.texture = load(fx_path)
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.size = Vector2(128, 128)
	fx_layer.add_child(texture)
	texture.global_position = view.global_position + Vector2(-16, -28)
	var tween: Tween = create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(texture, "modulate:a", 0.0, 0.25)
	tween.tween_callback(texture.queue_free)

func _find_unit_view(unit_id: String) -> Control:
	var view: Control = enemy_units.get_node_or_null(unit_id)
	if view == null:
		view = ally_units.get_node_or_null(unit_id)
	return view

func _show_result(title: String, message: String, button_text: String) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = button_text
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		controller.setup("res://data/units.json", "res://data/skills.json")
		pending_hero_action = null
		selected_skill_id = "attack"
		_spawn_unit_views()
		_refresh_all()
		dialog.queue_free()
	)
	dialog.popup_centered()
