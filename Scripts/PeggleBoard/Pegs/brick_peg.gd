@tool
class_name BrickPeg
extends StaticBody2D

signal claim_changed

@export_category("Gameplay")
@export var max_hits: int = 2

@export var texture_unclaimed: Texture2D
@export var texture_player: Texture2D
@export var texture_player_hit: Texture2D
@export var texture_ai: Texture2D
@export var texture_ai_hit: Texture2D

@export var hit_frame_duration: float = 0.15

@onready var hit_area: Area2D = $Area2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var area_collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var visual_polygon: Polygon2D = $Polygon2D

var claimed_turn: int = -1
var claimed_owner: String = "unclaimed"
var hit_count: int = 0
var is_vanished: bool = false
var _hit_token: int = 0


func _ready() -> void:
	add_to_group("pegs")
	if not Engine.is_editor_hint():
		hit_area.body_entered.connect(change_peg_colour)
	_update_texture()


func set_polygon(points: PackedVector2Array) -> void:
	if not is_node_ready():
		await ready

	collision_polygon.polygon = points
	area_collision_polygon.polygon = points
	visual_polygon.polygon = points
	_update_uvs()


func _update_uvs() -> void:
	if visual_polygon == null or visual_polygon.polygon.is_empty():
		return

	var tex: Texture2D = visual_polygon.texture
	if tex == null:
		return

	var tex_size: Vector2 = tex.get_size()
	var points: PackedVector2Array = visual_polygon.polygon
	var uvs: PackedVector2Array = PackedVector2Array()
	uvs.resize(points.size())

	if points.size() == 4:
		uvs[0] = Vector2(0.0, 0.0)
		uvs[1] = Vector2(tex_size.x, 0.0)
		uvs[2] = Vector2(tex_size.x, tex_size.y)
		uvs[3] = Vector2(0.0, tex_size.y)
	else:
		var min_p: Vector2 = points[0]
		var max_p: Vector2 = points[0]
		for p: Vector2 in points:
			min_p = min_p.min(p)
			max_p = max_p.max(p)

		var bounds_size: Vector2 = max_p - min_p
		if bounds_size.x == 0.0 or bounds_size.y == 0.0:
			return

		for i: int in points.size():
			var norm: Vector2 = (points[i] - min_p) / bounds_size
			uvs[i] = norm * tex_size

	visual_polygon.uv = uvs


func change_peg_colour(body: Node2D) -> void:
	if is_vanished:
		return

	if not body.get_meta("is_peggle_ball", false):
		return

	EventBus.peg_hit_sound_update.emit()

	var new_claimed_turn: int = int(body.get_meta("turn_owner", -1))
	if new_claimed_turn == -1:
		return

	var ball_owner: String = String(body.get_meta("ball_owner", "default"))

	if claimed_turn == new_claimed_turn:
		hit_count += 1

		if hit_count >= max_hits:
			is_vanished = true
			hit_area.set_deferred("monitoring", false)
			collision_polygon.set_deferred("disabled", true)

			await _play_hit_feedback(ball_owner)
			visible = false
			claim_changed.emit()
			return

		_play_hit_feedback(ball_owner)
		claim_changed.emit()
		return

	claimed_turn = new_claimed_turn
	claimed_owner = ball_owner
	hit_count = 1

	_play_hit_feedback(ball_owner)
	claim_changed.emit()


func _play_hit_feedback(ball_owner: String) -> void:
	_hit_token += 1
	var current_token: int = _hit_token

	if ball_owner == "player":
		visual_polygon.texture = texture_player_hit
	elif ball_owner == "ai":
		visual_polygon.texture = texture_ai_hit

	_update_uvs()

	var timer: SceneTreeTimer = get_tree().create_timer(hit_frame_duration)
	await timer.timeout

	if not is_inside_tree():
		return

	if _hit_token == current_token:
		_update_texture()


func _update_texture() -> void:
	if not is_node_ready() or visual_polygon == null:
		return

	match claimed_owner:
		"player":
			visual_polygon.texture = texture_player
		"ai":
			visual_polygon.texture = texture_ai
		_:
			visual_polygon.texture = texture_unclaimed

	_update_uvs()


func reset_peg() -> void:
	is_vanished = false
	visible = true
	collision_polygon.disabled = false
	hit_area.monitoring = true
	claimed_turn = -1
	claimed_owner = "unclaimed"
	hit_count = 0
	_update_texture()


func get_claimed_turn() -> int:
	return claimed_turn
