@tool
class_name BrickPeg
extends StaticBody2D

signal claim_changed

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
	if visual_polygon == null or visual_polygon.polygon.size() != 4:
		return

	var tex_size: Vector2 = Vector2.ONE
	if visual_polygon.texture != null:
		tex_size = visual_polygon.texture.get_size()

	var uvs: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(tex_size.x, 0.0),
		Vector2(tex_size.x, tex_size.y),
		Vector2(0.0, tex_size.y)
	])
	visual_polygon.uv = uvs


func change_peg_colour(body: Node2D) -> void:
	if body.get_meta("is_peggle_ball", false) != true:
		return

	EventBus.peg_hit_sound_update.emit()

	var new_claimed_turn: int = int(body.get_meta("turn_owner", -1))
	if new_claimed_turn == -1:
		return

	var ball_owner: String = String(body.get_meta("ball_owner", "default"))
	claimed_owner = ball_owner

	_play_hit_feedback(ball_owner)

	if claimed_turn == new_claimed_turn:
		return

	claimed_turn = new_claimed_turn
	claim_changed.emit()


func _play_hit_feedback(ball_owner: String) -> void:
	_hit_token += 1
	var current_token: int = _hit_token

	if ball_owner == "player":
		visual_polygon.texture = texture_player_hit
	elif ball_owner == "ai":
		visual_polygon.texture = texture_ai_hit

	_update_uvs()

	await get_tree().create_timer(hit_frame_duration).timeout

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
	claimed_turn = -1
	claimed_owner = "unclaimed"
	_update_texture()


func get_claimed_turn() -> int:
	return claimed_turn
