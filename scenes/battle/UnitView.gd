extends Control

@onready var sprite: TextureRect = $Sprite
@onready var ring: TextureRect = $Ring
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HpBar

var unit_id: String = ""
var idle_tween: Tween = null
var action_tween: Tween = null
var motion_tween: Tween = null
var base_position: Vector2
var base_scale: Vector2 = Vector2.ONE
var idle_texture: Texture2D = null
var animations: Dictionary = {}

func _ready() -> void:
	base_position = position
	base_scale = scale
	sprite.pivot_offset = sprite.size * 0.5

func bind_unit(unit) -> void:
	unit_id = unit.id
	animations = unit.animations
	name_label.text = unit.display_name
	_set_ring_for_side(unit.side)
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.hp
	if unit.sprite_sheet_path != "" and ResourceLoader.exists(unit.sprite_sheet_path):
		idle_texture = _make_sheet_frame_texture(unit.sprite_sheet_path, unit.sprite_sheet_columns, unit.sprite_sheet_rows, unit.combat_frame)
	elif unit.sprite_path != "" and ResourceLoader.exists(unit.sprite_path):
		idle_texture = load(unit.sprite_path)
	if action_tween == null or not action_tween.is_running():
		sprite.texture = idle_texture
	modulate = Color.WHITE if unit.is_alive() else Color(0.35, 0.35, 0.35, 0.8)
	if unit.is_alive():
		_start_idle_motion()
	else:
		_stop_idle_motion()

func _set_ring_for_side(side: String) -> void:
	var path: String = "res://assets/ui/battle/ring_blue.png"
	if side == "enemy":
		path = "res://assets/ui/battle/ring_red.png"
	elif side == "pet":
		path = "res://assets/ui/battle/ring_gold.png"
	if ResourceLoader.exists(path):
		ring.texture = load(path)

func flash_damage() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.55, 0.55), 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func play_action(action_type: String, target_global_position: Vector2 = Vector2.ZERO) -> void:
	if action_tween != null:
		action_tween.kill()
	if motion_tween != null:
		motion_tween.kill()
	if idle_tween != null:
		idle_tween.pause()
	var has_sprite_animation: bool = _play_sprite_animation(action_type)
	_play_action_motion(action_type, target_global_position, has_sprite_animation)

func _play_action_motion(action_type: String, target_global_position: Vector2, has_sprite_animation: bool) -> void:
	var start_position: Vector2 = position
	var direction: Vector2 = Vector2.LEFT
	if target_global_position != Vector2.ZERO:
		direction = (target_global_position - global_position).normalized()
	var lunge_offset: Vector2 = direction * (34.0 if has_sprite_animation else 24.0)
	motion_tween = create_tween()
	match action_type:
		"attack":
			motion_tween.tween_property(self, "position", start_position + lunge_offset, 0.14)
			motion_tween.tween_property(self, "position", start_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"cast":
			motion_tween.tween_property(self, "scale", base_scale * 1.06, 0.18)
			motion_tween.tween_property(self, "scale", base_scale, 0.24)
		"hurt":
			motion_tween.tween_property(self, "position", start_position - direction * 16.0, 0.08)
			motion_tween.parallel().tween_property(self, "scale", Vector2(base_scale.x * 1.08, base_scale.y * 0.92), 0.08)
			motion_tween.tween_property(self, "position", start_position, 0.14)
			motion_tween.parallel().tween_property(self, "scale", base_scale, 0.14)
		"defend":
			motion_tween.tween_property(self, "position", start_position + Vector2(0, 8), 0.10)
			motion_tween.parallel().tween_property(self, "scale", Vector2(base_scale.x * 1.08, base_scale.y * 0.92), 0.10)
			motion_tween.tween_property(self, "position", start_position, 0.20)
			motion_tween.parallel().tween_property(self, "scale", base_scale, 0.20)
		_:
			motion_tween.tween_property(self, "position", start_position + Vector2(0, -8), 0.12)
			motion_tween.tween_property(self, "position", start_position, 0.16)
	motion_tween.tween_callback(_resume_idle_motion)

func _play_sprite_animation(action_type: String) -> bool:
	if not animations.has(action_type):
		return false
	var spec: Dictionary = animations.get(action_type, {})
	var sheet_path: String = str(spec.get("sheet", ""))
	if sheet_path == "" or not ResourceLoader.exists(sheet_path):
		return false
	var columns: int = int(spec.get("columns", 1))
	var rows: int = int(spec.get("rows", 1))
	var frame_count: int = int(spec.get("frames", columns * rows))
	var fps: float = maxf(float(spec.get("fps", 10.0)), 1.0)
	action_tween = create_tween()
	for frame_index: int in range(frame_count):
		action_tween.tween_callback(_set_animation_frame.bind(sheet_path, columns, rows, frame_index))
		action_tween.tween_interval(1.0 / fps)
	action_tween.tween_callback(_restore_idle_texture)
	return true

func _set_animation_frame(sheet_path: String, columns: int, rows: int, frame: int) -> void:
	sprite.texture = _make_sheet_frame_texture(sheet_path, columns, rows, frame)

func _restore_idle_texture() -> void:
	if idle_texture != null:
		sprite.texture = idle_texture

func _make_sheet_frame_texture(path: String, columns: int, rows: int, frame: int) -> AtlasTexture:
	var sheet: Texture2D = load(path)
	var safe_columns: int = maxi(columns, 1)
	var safe_rows: int = maxi(rows, 1)
	var frame_count: int = safe_columns * safe_rows
	var safe_frame: int = clampi(frame, 0, frame_count - 1)
	var cell_size: Vector2 = Vector2(sheet.get_width() / safe_columns, sheet.get_height() / safe_rows)
	var frame_column: int = safe_frame % safe_columns
	var frame_row: int = int(safe_frame / safe_columns)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		Vector2(frame_column * cell_size.x, frame_row * cell_size.y),
		cell_size
	)
	return atlas

func _start_idle_motion() -> void:
	if idle_tween != null:
		return
	idle_tween = create_tween().set_loops()
	if animations.has("idle"):
		var spec: Dictionary = animations.get("idle", {})
		var sheet_path: String = str(spec.get("sheet", ""))
		var columns: int = int(spec.get("columns", 1))
		var rows: int = int(spec.get("rows", 1))
		var frame_count: int = int(spec.get("frames", columns * rows))
		var fps: float = maxf(float(spec.get("fps", 6.0)), 1.0)
		if sheet_path != "" and ResourceLoader.exists(sheet_path):
			for frame_index: int in range(frame_count):
				idle_tween.tween_callback(_set_animation_frame.bind(sheet_path, columns, rows, frame_index))
				idle_tween.tween_interval(1.0 / fps)
		else:
			idle_tween.tween_property(sprite, "position:y", sprite.position.y - 4.0, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			idle_tween.tween_property(sprite, "position:y", sprite.position.y, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		idle_tween.tween_property(sprite, "position:y", sprite.position.y - 4.0, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle_tween.tween_property(sprite, "position:y", sprite.position.y, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_idle_motion() -> void:
	if idle_tween != null:
		idle_tween.kill()
		idle_tween = null

func _resume_idle_motion() -> void:
	if idle_tween != null:
		idle_tween.play()
